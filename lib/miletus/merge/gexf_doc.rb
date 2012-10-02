module Miletus::Merge
  class GexfDoc
    include Miletus::NamespaceHelper

    def initialize(concepts)
      @concepts = concepts
    end

    def to_doc
      gexf_graph_doc do |xml|
        xml.attributes(:class => 'node') {
          xml.attribute(:id => 0, :title => 'type', :type => 'string')
          xml.attribute(:id => 1, :title => 'subtype', :type => 'string')
          xml.attribute(:id => 2, :title => 'facets', :type => 'integer')
          xml.attribute(:id => 3,
            :title => 'relationships_outbound', :type => 'integer')
        }
        xml.nodes {
          @concepts.each { |c| node(xml, c) }
        }
        xml.edges {
          @concepts.each { |c| edge(xml, c) }
        }
      end
    end

    def to_xml
      to_doc.to_xml
    end

    private

    def node(xml, concept)
      xml.node(:id => concept.key, :label => concept.title) {
        xml.attvalues {
          xml.attvalue(:for => 0, :value => concept.type)
          xml.attvalue(:for => 1, :value => concept.subtype)
          xml.attvalue(:for => 2, :value => concept.facets.size)
          xml.attvalue(:for => 3,
            :value => concept.outbound_related_concept_keys.count)
        }
      }
    end

    def edge(xml, concept)
      concept_keys = @concepts.map{|c| c.key}.to_set
      concept.outbound_related_concept_keys.each do |oc_key|
        xml.edge(
          :id => "%s|%s" % [concept.key, oc_key],
          :source => concept.key,
          :target => oc_key) if concept_keys.include?(oc_key)
      end
    end

    def gexf_graph_doc
      Nokogiri::XML::Builder.new do |xml|
        xml.gexf(:xmlns => ns_by_prefix('gexf').uri, :version => '1.2') {
          xml.graph(:mode => 'static', :defaultedgetype => 'directed') {
            yield(xml) if block_given?
          }
        }
      end
    end
  end
end
