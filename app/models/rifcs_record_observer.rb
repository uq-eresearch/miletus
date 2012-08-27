require 'nokogiri'
require 'miletus'

class RifcsRecordObserver < ActiveRecord::Observer
  include Miletus::NamespaceHelper

  observe Miletus::Harvest::OAIPMH::RIFCS::Record

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

  def self.run_job(job)
    job.delay.run
  end

  class CreateFacetJob < Struct.new(:record)
    def run
      concept = Miletus::Merge::Concept.find_existing(record.to_rif)
      concept ||= Miletus::Merge::Concept.create()
      concept.facets.create(:metadata => record.to_rif)
    end
  end

  class UpdateFacetJob < Struct.new(:record)
    def run
      facet = Miletus::Merge::Facet.find_existing(record.to_rif)
      return CreateFacetJob.new(record).run if facet.nil?
      facet.metadata = record.to_rif
      facet.save!
    end
  end

  class RemoveFacetJob < Struct.new(:record)
    def run
      facet = Miletus::Merge::Facet.find_existing(record.to_rif)
      facet.destroy unless facet.nil?
    end
  end

end
