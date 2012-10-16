require 'miletus'

class RecordController < ApplicationController

  def index
    concepts = Miletus::Merge::Concept.order('updated_at DESC').all
    sorted_concepts = concepts.each_with_object({}) do |c, ch|
      ch[c.type] ||= []
      ch[c.type] << c
    end
    @concepts_by_type = Hash[sorted_concepts.sort]
  end

  def view
    @concept = Miletus::Merge::Concept.find_by_id!(params[:id])
    @doc = Nokogiri::XML(@concept.to_rif)
  end

  def graph
    # No data required
  end

  def gexf
    if params.key?(:id)
      concept = Miletus::Merge::Concept.find_by_id!(params[:id])
      xml = concept.to_gexf
    else
      xml = Miletus::Merge::Concept.to_gexf
    end
    render :text => xml, :content_type => 'text/xml'
  end


end
