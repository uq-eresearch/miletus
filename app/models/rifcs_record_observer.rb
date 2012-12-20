require 'nokogiri'
require 'miletus'

class RifcsRecordObserver < ActiveRecord::Observer
  include Miletus::NamespaceHelper

  # Handles pretty much anything that provides :to_rif
  observe(
    Miletus::Harvest::Document::RDCAtom,
    Miletus::Harvest::Document::RIFCS,
    Miletus::Harvest::OAIPMH::RIFCS::Record)

  def after_metadata_change(record)
    if record.deleted?
      RemoveFacetJob.new(record).delay.run
    else
      UpdateFacetJob.new(record).delay.run
    end
  end

  def after_destroy(record)
    RemoveFacetJob.new(record).delay.run
  end

  class AbstractJob < Struct.new(:record)
    # Split RIF-CS document into multiple documents representing a single facet
    def split_rifcs_document
      xml = record.to_rif_file rescue record.to_rif
      return [] if xml.nil? || xml == ''
      SplitDocumentWrapper.new(Nokogiri::XML::Reader(xml))
    end

    private

    class SplitDocumentWrapper < Struct.new(:reader)
      include Enumerable

      def each
        reader.each do |node|
          # Ignore nodes which aren't elements - they're not important here
          next unless node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
          case node.name
          when 'registryObjects'
            populate_template_root(node)
          when 'registryObject'
            yield render_with_template_doc(node)
          end
        end
      end

      private

      # Clone the template doc, then insert the node as the first child of
      # the root node.
      def render_with_template_doc(node)
        doc = template_doc.clone
        # Use document fragment to clone the node itself
        doc.root << doc.fragment(node.outer_xml).children.first
        doc.to_xml
      end

      # Create a document to clone for the separate ones
      def template_doc
        @template_doc ||= Nokogiri::XML::Document.new()
      end

      # Populate root for our template document
      def populate_template_root(node)
        namespaces = node.namespaces
        template_doc.root = template_doc.create_element(node.name, namespaces)
        node.attributes.each do |k,v|
          next if namespaces.key?(k)
          # Kludge to handle schemaLocation namespace disappearing
          case k
          when 'schemaLocation'
            template_doc.root.set_attribute('xsi:%s' % k, v)
          else
            template_doc.root.set_attribute(k, v)
          end
        end
      end

    end

  end

  class UpdateFacetJob < AbstractJob
    def run
      existing_links = record.facet_links.all
      facets = []
      split_rifcs_document.each do |xml|
        facet = Miletus::Merge::Facet.find_existing(xml)
        if facet.nil?
          concept = Miletus::Merge::Concept.find_existing(xml)
          concept ||= Miletus::Merge::Concept.create()
          facet = concept.facets.create(:metadata => xml)
        else
          facet.metadata = xml
          facet.save!
        end
        facets << facet
      end
      # Remove links (and facets) for no longer present facets
      existing_links.reject{|l| facets.include?(l.facet)}.each do |l|
        existing_links.delete(l)
        l.destroy
      end
      # Refresh record to update the existing links
      record.reload
      # Create new links where necessary
      (facets - existing_links.map(&:facet)).each do |facet|
        record.facet_links.create(:facet => facet)
      end
    end
  end

  class RemoveFacetJob < AbstractJob
    def run
      record.facet_links.destroy_all
    end
  end

end
