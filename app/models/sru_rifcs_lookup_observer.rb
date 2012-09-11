require 'nokogiri'
require 'miletus'

class SruRifcsLookupObserver < ActiveRecord::Observer

  observe Miletus::Merge::Concept
  observe Miletus::Merge::Facet

  def find_sru_records(concept_or_facet)
    concept = concept_or_facet.concept rescue concept_or_facet
    Miletus::Harvest::SRU::Interface.find(:all).each do |interface|
      self.class.run_job(JobProcessor.new(concept, interface))
    end
  end

  alias :after_save :find_sru_records

  def self.run_job(job)
    job.delay.run
  end

  class JobProcessor < Struct.new(:concept, :interface)
    include Miletus::NamespaceHelper

    def run
      identifiers = \
        concept.indexed_attributes.where(
          :key => 'identifier').pluck(:value) +
        concept.indexed_attributes.where(
          :key => 'email').pluck(:value).map {|e| "mailto:%s" % e }

      related_keys = concept.indexed_attributes.where(
        :key => 'relatedKey').pluck(:value)

      xml = nil

      identifiers.detect do |identifier|
        xml = interface.lookup_by_identifier(identifier)
      end
      return nil if xml.nil?

      facet = Miletus::Merge::Facet.find_existing(xml)
      if facet.nil?
        facet = concept.facets.create(:metadata => xml)
      else
        facet.metadata = xml
      end

      if facet.concept == concept
        facet.reindex_concept
        new_related_keys = concept.indexed_attributes.where(
          :key => 'relatedKey').pluck(:value) - related_keys
        new_related_keys.each do |key|
          xml = interface.lookup_by_identifier(key)
          next if xml.nil?
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


end
