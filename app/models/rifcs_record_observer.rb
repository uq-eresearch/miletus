require 'nokogiri'
require 'miletus'

class RifcsRecordObserver < ActiveRecord::Observer
  include Miletus::NamespaceHelper

  # Handles pretty much anything that provides :to_rif
  observe(
    Miletus::Harvest::Atom::RDC::Entry,
    Miletus::Harvest::OAIPMH::RIFCS::Record)

  def after_create(record)
    self.class.run_job(CreateFacetJob.new(record))
  end

  def after_update(record)
    if record.deleted?
      self.class.run_job(RemoveFacetJob.new(record))
    else
      self.class.run_job(UpdateFacetJob.new(record))
    end
  end

  def after_destroy(record)
    self.class.run_job(RemoveFacetJob.new(record))
  end

  def self.run_job(job)
    job.delay.run
  end

  class AbstractJob < Struct.new(:record)
    # Split RIF-CS document into multiple documents representing a single facet
    def split_rifcs_document(xml)
      combined_doc = Nokogiri::XML(xml)
      combined_doc.root.children.select do |node|
        node.element?
      end.map do |element|
        root = combined_doc.root.clone
        root.children = element.clone
        root.to_xml
      end
    end
  end

  class CreateFacetJob < AbstractJob
    def run
      split_rifcs_document(record.to_rif).each do |xml|
        concept = Miletus::Merge::Concept.find_existing(xml)
        concept ||= Miletus::Merge::Concept.create()
        concept.facets.create(:metadata => xml)
      end
    end
  end

  class UpdateFacetJob < AbstractJob
    def run
      split_rifcs_document(record.to_rif).each do |xml|
        facet = Miletus::Merge::Facet.find_existing(xml)
        return CreateFacetJob.new(entry).run if facet.nil?
        facet.metadata = xml
        facet.save!
      end
    end
  end

  class RemoveFacetJob < AbstractJob
    def run
      split_rifcs_document(record.to_rif).each do |xml|
        facet = Miletus::Merge::Facet.find_existing(xml)
        facet.destroy unless facet.nil?
      end
    end
  end

end
