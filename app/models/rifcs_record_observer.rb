require 'nokogiri'
require 'miletus'

class RifcsRecordObserver < ActiveRecord::Observer
  include Miletus::NamespaceHelper

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

    def run
      case action
      when :create
        concept = Miletus::Merge::Concept.find_existing(record.to_rif)
        concept ||= Miletus::Merge::Concept.create()
        concept.facets.create(:metadata => record.to_rif)
      when :update
        facet = Miletus::Merge::Facet.find_existing(record.to_rif)
        return JobProcessor.new(:create, record).run if facet.nil?
        facet.metadata = record.to_rif
        facet.save!
      when :remove
        facet = Miletus::Merge::Facet.find_existing(record.to_rif)
        unless facet.nil?
          facet.destroy
        end
      end
    end

  end

end
