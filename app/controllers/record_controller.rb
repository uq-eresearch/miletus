require 'miletus'

class RecordController < ApplicationController

  def index
    @stats = {
      'OAI-PMH input records' => \
        Miletus::Harvest::OAIPMH::RIFCS::Record.all.count,
      'OAI-PMH endpoints' => \
        Miletus::Harvest::OAIPMH::RIFCS::RecordCollection.all.count,
      'SRU interfaces' => Miletus::Harvest::SRU::Interface.all.count,
      'concepts' => Miletus::Merge::Concept.all.count,
      'facets' => Miletus::Merge::Facet.all.count,
      'OAI-PMH output records' => Miletus::Output::OAIPMH::Record.all.count,
    }

    @concepts = Miletus::Merge::Concept.order('updated_at DESC').all
  end

  def recheck_sru
    if params.key?(:id)
      concept = Miletus::Merge::Concept.find_by_id!(params[:id])
      SruRifcsLookupObserver.instance.find_sru_records(concept)
      redirect_to :action => :view, :id => concept.id
    else
      Miletus::Merge::Concept.all.each do |concept|
        SruRifcsLookupObserver.instance.find_sru_records(concept)
      end
      redirect_to :action => :index
    end
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
