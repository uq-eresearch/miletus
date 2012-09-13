require 'nokogiri'
require 'miletus'

class SruRifcsLookupObserver < ActiveRecord::Observer

  observe Miletus::Merge::Concept
  observe Miletus::Merge::Facet

  def find_sru_records(concept_or_facet)
    concept = concept_or_facet
    if concept_or_facet.respond_to?(:concept)
      facet = concept_or_facet
      return if blocked_key?(facet.key)
      concept = facet.concept
    end
    Miletus::Harvest::SRU::Interface.find(:all).each do |interface|
      self.class.run_job(JobProcessor.new(concept, interface))
    end
  end

  alias :after_save :find_sru_records

  def blocked_key?(key)
    @blocked_keys ||= []
    @blocked_keys.include?(key)
  end

  def prevent_loop(key, &block)
    @blocked_keys ||= []
    @blocked_keys << key
    block.call
    @blocked_keys.delete(key)
  end

  def self.run_job(job)
    job.delay.run
  end

  class JobProcessor < Struct.new(:concept, :interface)
    include Miletus::NamespaceHelper
    extend Forwardable

    def_delegator 'SruRifcsLookupObserver.instance', :prevent_loop

    def run
      related_keys = concept.indexed_attributes.where(
        :key => 'relatedKey').pluck(:value)

      xml = lookup_using_identifiers(concept)
      return nil if xml.nil?

      # Create or update facet
      prevent_loop(Miletus::Merge::Facet.global_key(xml)) do
        facet = save_facet(xml)
        # Import related objects
        facet.reindex_concept
        new_related_keys = facet.concept.indexed_attributes.where(
          :key => 'relatedKey').pluck(:value) - related_keys
        new_related_keys.each { |k| import_related_object(k) }
      end
    end

    private

    def lookup_using_identifiers(concept)
      identifiers = \
        concept.indexed_attributes.where(
          :key => 'identifier').pluck(:value) +
        concept.indexed_attributes.where(
          :key => 'email').pluck(:value).map {|e| "mailto:%s" % e }
      identifiers.detect do |identifier|
        return interface.lookup_by_identifier(identifier)
      end
    end

    def save_facet(xml)
      facet = Miletus::Merge::Facet.find_existing(xml)
      facet ||= concept.facets.new
      facet.metadata = xml
      facet.save!
      facet.reindex_concept
      facet
    end

    def import_related_object(key)
      xml = interface.lookup_by_identifier(key)
      return if xml.nil?
      prevent_loop(Miletus::Merge::Facet.global_key(xml)) do
        facet = Miletus::Merge::Facet.find_existing(xml)
        if facet.nil?
          related_concept = Miletus::Merge::Concept.find_existing(xml)
          related_concept ||= Miletus::Merge::Concept.create()
          related_concept.facets.create(:metadata => xml)
        else
          facet.metadata = xml
        end
      end
    end

  end


end
