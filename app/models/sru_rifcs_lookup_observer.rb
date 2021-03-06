require 'nokogiri'
require 'miletus'

class SruRifcsLookupObserver < ActiveRecord::Observer

  observe Miletus::Merge::Facet

  def find_sru_records(facet)
    return if blocked_key?(facet.key)
    concept = facet.concept
    find_sru_records_for_concept(concept) unless concept.nil?
  end

  def find_sru_records_for_concept(concept)
    Miletus::Harvest::SRU::Interface.all.each do |interface|
      if interface.suitable_type?(concept.type)
        JobProcessor.new(concept, interface).delay(:queue => 'lookup').run
      end
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

  class JobProcessor < Struct.new(:concept, :interface)
    include Miletus::NamespaceHelper
    extend Forwardable

    def_delegator 'SruRifcsLookupObserver.instance', :prevent_loop

    def run
      xml = lookup_using_identifiers(concept)
      return nil if xml.nil?

      # Create or update facet
      prevent_loop(Miletus::Merge::Facet.global_key(xml)) do
        facet = save_facet(xml)
        # Import related objects
        facet.reindex_concept
        related_keys = facet.concept.reload.indexed_attributes.where(
          :key => 'relatedKey').pluck(:value)
        related_keys.each { |k| import_related_object(k) }
        # Reindex to refresh the cached keys
        concept.reindex
      end
    end

    private

    def lookup_using_identifiers(concept)
      identifiers = \
        concept.indexed_attributes.where(
          :key => 'identifier').pluck(:value) +
        concept.facets.pluck(:key) + # Handle systems that only index on key
        [concept.key] + # Handle downstream system lookups
        concept.indexed_attributes.where(
          :key => 'email').pluck(:value).map {|e| "mailto:%s" % e }
      identifiers.each do |identifier|
        Rails.logger.info \
          "Using #{interface.endpoint} for identifier lookup (#{identifier})"
        xml = interface.lookup_by_identifier(identifier)
        return xml unless xml.nil?
      end
      nil
    end

    def save_facet(xml)
      facet = Miletus::Merge::Facet.find_existing(xml)
      facet ||= concept.facets.new
      facet.metadata = xml
      facet.save!
      facet.reindex_concept
      # If this facet has highlighted duplicate concepts, merge them
      if facet.concept.id != concept.id
        merge_concepts = [concept.reload, facet.concept]
        concept = Miletus::Merge::Concept.merge(merge_concepts)
      end
      facet
    end

    def import_related_object(key)
      Rails.logger.info \
        "Using #{interface.endpoint} for related key lookup (#{key})"
      xml = interface.lookup_by_identifier(key)
      return if xml.nil?
      prevent_loop(Miletus::Merge::Facet.global_key(xml)) do
        Miletus::Merge::Facet.create_or_update_by_metadata(xml)
      end
    end

  end


end
