require 'nokogiri'
require 'miletus'

class RifcsRecordObserver < ActiveRecord::Observer
  include Miletus::Output::OAIPMH::NamespaceHelper

  observe Miletus::Harvest::OAIPMH::RIFCS::Record

  def after_create(record)
    self.class.run_job(JobProcessor.new(:create, record))
  end

  def after_update(record)
    self.class.run_job(JobProcessor.new(:update, record)) unless record.deleted
  end

  def after_destroy(record)
    #self.class.run_job(JobProcessor.new(:remove, record))
  end

  def self.run_job(job)
    job.delay.run
  end

  class JobProcessor < Struct.new(:action, :record)
    include Miletus::Output::OAIPMH::NamespaceHelper

    def run
      case action
      when :create
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
      when :update
        key_nodes = Nokogiri::XML(record.metadata).xpath('//rif:key', ns_decl)
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
        return JobProcessor.new(:create, record).run if existing.empty?
        existing_record = \
          Miletus::Output::OAIPMH::Record.find_by_id(existing.first)
        existing_record.metadata = record.to_rif
        existing_record.save!
      end
    end

    private

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
