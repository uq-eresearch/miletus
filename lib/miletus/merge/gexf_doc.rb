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
        edges(xml, @concepts)
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
          keys = concept.outbound_related_concept_keys
          xml.attvalue(:for => 3, :value => (keys.nil? ? 0 : keys.count))
        }
      }
    end

    def edges(xml, concepts)
      xml.edges {
        concept_keys = concepts.map{|c| c.key}.to_set
        concepts.each do |c|
          next if c.outbound_related_concept_keys.nil?
          c.outbound_related_concept_keys.each do |oc_key|
            xml.edge(
              :id => "%s|%s" % [c.key, oc_key],
              :source => c.key,
              :target => oc_key) if concept_keys.include?(oc_key)
          end
        end
      }
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
