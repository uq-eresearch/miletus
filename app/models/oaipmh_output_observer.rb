require 'miletus'

class OaipmhOutputObserver < ActiveRecord::Observer
  include Miletus::NamespaceHelper

  observe Miletus::Merge::Concept
  observe Miletus::Merge::Facet

  def update_record(concept_or_facet)
    concept = concept_or_facet.concept rescue concept_or_facet
    Rails.logger.info("Updating OAIPMH output record for %s" % concept)
    update_record_from_concept(concept)
    Rails.logger.info(
      "Updating related OAIPMH output records for %s including: %s" %
      [concept, concept.related_concepts.inspect])
    concept.related_concepts.each do |related_concept|
      update_record_from_concept(related_concept)
    end
  end

  alias :after_save :update_record
  alias :after_update :update_record

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
