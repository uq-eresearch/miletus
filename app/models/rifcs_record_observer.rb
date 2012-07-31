require 'nokogiri'
require 'miletus'

class RifcsRecordObserver < ActiveRecord::Observer
  include Miletus::Output::OAIPMH::NamespaceHelper

  observe Miletus::Harvest::OAIPMH::RIFCS::Record

  def after_create(record)
    self.class.run_job(JobProcessor.new(:create, record))
  end

  def after_update(record)
    if record.deleted?
      self.class.run_job(JobProcessor.new(:remove, record))
    else
      self.class.run_job(JobProcessor.new(:update, record))
    end
  end

  def self.run_job(job)
    job.delay.run
  end

  class JobProcessor < Struct.new(:action, :record)
    include Miletus::Output::OAIPMH::NamespaceHelper

    def run
      case action
      when :create
        existing_record = get_existing_output_record(record)
        return JobProcessor.new(:update, record).run unless existing_record.nil?
        output_record = Miletus::Output::OAIPMH::Record.new(
          :metadata => record.to_rif
        )
        output_record.save!
        Miletus::Output::OAIPMH::IndexedAttribute\
          .find_or_create_by_key_and_value(
            :record => output_record,
            :key => 'source_rifcs_endpoint_and_key',
            :value => retrive_global_key(record)
          )
        Nokogiri::XML(record.metadata).xpath(
          '//rif:identifier', ns_decl).each do |e|
            Miletus::Output::OAIPMH::IndexedAttribute\
              .find_or_create_by_key_and_value(
                :record => output_record,
                :key => 'identifier',
                :value => e.content.strip
              )
          end
      when :update
        existing_record = get_existing_output_record(record)
        return JobProcessor.new(:create, record).run if existing_record.nil?
        existing_record.metadata = record.to_rif
        existing_record.save!
      when :remove
        existing_record = get_existing_output_record(record)
        unless existing_record.nil?
          existing_record.deleted = true
          existing_record.save!
        end
      end
    end

    private

    def get_existing_output_record(input_record)
      get_existing_output_record_by_key(input_record) or
        get_existing_output_record_by_identifier(input_record)
    end

    def get_existing_output_record_by_key(input_record)
      key_nodes = Nokogiri::XML(record.metadata).xpath(
        '//rif:registryObject/rif:key', ns_decl)
      existing = key_nodes.map do |e|
        tbl_name = Miletus::Output::OAIPMH::IndexedAttribute.table_name.to_sym
        key = [record.record_collection.endpoint, e.content.strip].join('|')
        Miletus::Output::OAIPMH::Record.joins(:indexed_attributes).where(
          tbl_name => {
            :key => 'source_rifcs_endpoint_and_key',
            :value => retrive_global_key(record)
          }
        ).pluck(:record_id)
      end.flatten
      return nil if existing.empty?
      Miletus::Output::OAIPMH::Record.find_by_id(existing.first)
    end

    def get_existing_output_record_by_identifier(input_record)
      id_nodes = Nokogiri::XML(record.metadata).xpath(
        '//rif:identifier', ns_decl)
      existing = id_nodes.map do |e|
        tbl_name = Miletus::Output::OAIPMH::IndexedAttribute.table_name.to_sym
        key = [record.record_collection.endpoint, e.content.strip].join('|')
        Miletus::Output::OAIPMH::Record.joins(:indexed_attributes).where(
          tbl_name => {
            :key => 'identifier',
            :value => e.content.strip
          }
        ).pluck(:record_id)
      end.flatten
      return nil if existing.empty?
      Miletus::Output::OAIPMH::Record.find_by_id(existing.first)
    end

    def retrive_global_key(input_record)
      doc = Nokogiri::XML(input_record.to_rif)
      key_e = doc.at_xpath('//rif:key', ns_decl)
      begin
        "%s|%s" % [input_record.record_collection.endpoint, key_e.content.strip]
      rescue NoMethodError
        nil
      end
    end

  end

end
