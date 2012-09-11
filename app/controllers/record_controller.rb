require 'miletus'

class RecordController < ApplicationController

  def view
    concept = Miletus::Merge::Concept.find_by_key! params[:key]
    @doc = Nokogiri::XML(concept.to_rif)
  end


end
