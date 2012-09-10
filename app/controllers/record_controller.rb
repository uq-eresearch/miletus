require 'miletus'

class RecordController < ApplicationController

  def view
    concept = Miletus::Merge::Concept.find_by_key! params[:key]
    @rifcs = concept.to_rif
  end


end
