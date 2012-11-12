require 'miletus'

class RecordController < ApplicationController

  def index
    concepts = Miletus::Merge::Concept.order(:sort_key).all
    @concepts, @types = [], Set.new
    concepts.each do |c|
      next if c.type.nil?
      @types << c.type
      @concepts << c
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

  def sitemap
    extend Miletus::NamespaceHelper
    if Miletus::Merge::Concept.count > 0
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.urlset(:xmlns => ns_by_prefix('sitemap').uri) {
          Miletus::Merge::Concept.all.each do |concept|
            xml.url {
              url = URI::HTTP.build(
                :scheme => request.scheme,
                :host => request.host,
                :port => request.port,
                :path => concept_path(:id => concept.id)
              )
              xml.loc url
              xml.lastmod concept.updated_at.iso8601
            }
          end
        }
      end
      render :content_type => 'text/xml', :text => builder.to_xml
    else
      render :status => 404, :text => ''
    end
  end

end
