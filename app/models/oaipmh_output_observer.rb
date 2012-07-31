require 'miletus'

class OaipmhOutputObserver < ActiveRecord::Observer

  observe Miletus::Merge::Concept
  observe Miletus::Merge::Facet

  def update_record(concept_or_facet)
    concept = concept_or_facet.concept rescue concept_or_facet
    record = Miletus::Output::OAIPMH::Record.where(
      :underlying_concept_id => concept.id).first
    record ||= Miletus::Output::OAIPMH::Record.create().tap do |r|
      r.underlying_concept = concept
    end
    record.metadata = concept.to_rif
    record.save!
  end

  alias :after_save :update_record
  alias :after_update :update_record

end