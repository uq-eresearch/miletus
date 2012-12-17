require 'miletus'

class OaipmhOutputObserver < ActiveRecord::Observer
  include Miletus::NamespaceHelper

  observe(
    Miletus::Merge::Concept,
    Miletus::Merge::Facet)

  def update_record(concept_or_facet)
    concept_id = concept_or_facet.concept_id rescue concept_or_facet.id
    return if concept_id.nil? # It might have been an orphan facet
    UpdateJob.new(concept_id).delay(:queue => 'output').run
  end

  alias :after_save :update_record
  alias :after_update :update_record

  private

  class UpdateJob < Struct.new(:concept_id)

    def run
      # Handle concepts records by ignoring them
      return unless Miletus::Merge::Concept.exists? concept_id
      # Find concept
      concept = Miletus::Merge::Concept.find concept_id
      Rails.logger.info("Updating OAIPMH output record for %s" % concept)
      update_record_from_concept(concept)
      Rails.logger.info(
        "Updating related OAIPMH output records for %s including: %s" %
        [concept, concept.related_concepts.inspect])
      concept.related_concepts.each {|c| update_record_from_concept c }
    end

    private

    def update_record_from_concept(concept)
      record = Miletus::Output::OAIPMH::Record.where(
        :underlying_concept_id => concept.id).first
      record ||= Miletus::Output::OAIPMH::Record.create().tap do |r|
        r.underlying_concept = concept
      end
      record.metadata = concept.to_rif
      record.save!
    end

  end




end
