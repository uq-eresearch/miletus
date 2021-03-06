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
        }
        xml.nodes {
          @concepts.reject { |c| c.key.nil? }.each { |c| node(xml, c) }
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
        }
      }
    end

    def edges(xml, concepts)
      xml.edges {
        keys = all_keys(concepts)
        concepts.each do |c|
          valid_outbound_keys(keys, c).each do |oc_key|
            xml.edge(
              :id => "#{c.key}|#{oc_key}",
              :source => c.key,
              :target => oc_key)
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

    private

    def all_keys(concepts)
      # Get all the concept keys, remove nils, then produce frozen set
      concepts.map(&:key).compact.to_set.freeze
    end

    def valid_outbound_keys(all_keys, concept)
      all_keys.intersection(concept.outbound_related_concepts.map(&:key))
    end


  end
end
