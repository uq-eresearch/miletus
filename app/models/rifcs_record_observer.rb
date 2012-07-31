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
        concept = get_existing_concept(record)
        concept ||= Miletus::Merge::Concept.create()
        concept.facets.create(
          :key => retrive_global_key(record),
          :metadata => record.to_rif
        )
        Nokogiri::XML(record.metadata).xpath(
          '//rif:identifier', ns_decl).each do |e|
            concept.indexed_attributes.find_or_create_by_key_and_value(
              :key => 'identifier',
              :value => e.content.strip
            )
          end
      when :update
        facet = get_existing_facet(record)
        return JobProcessor.new(:create, record).run if facet.nil?
        facet.metadata = record.to_rif
        facet.save!
      when :remove
        facet = get_existing_facet(record)
        unless facet.nil?
          facet.destroy
        end
      end
    end

    private

    def get_existing_concept(input_record)
      id_nodes = Nokogiri::XML(input_record.to_rif).xpath(
        '//rif:identifier', ns_decl)
      existing = id_nodes.map do |e|
        Miletus::Merge::Concept.joins(:indexed_attributes).where(
          Miletus::Merge::IndexedAttribute.table_name.to_sym => {
            :key => 'identifier',
            :value => e.content.strip
          }
        ).pluck(:concept_id)
      end.flatten
      return nil if existing.empty?
      Miletus::Merge::Concept.find_by_id(existing.first)
    end

    def get_existing_facet(input_record)
      Miletus::Merge::Facet.find_by_key(retrive_global_key(record))
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
