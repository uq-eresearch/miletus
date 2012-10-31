require 'nokogiri'
require 'miletus'

class RifcsRecordObserver < ActiveRecord::Observer
  include Miletus::NamespaceHelper

  # Handles pretty much anything that provides :to_rif
  observe(
    Miletus::Harvest::Atom::RDC::Entry,
    Miletus::Harvest::Document::RIFCS,
    Miletus::Harvest::OAIPMH::RIFCS::Record)

  def after_create(record)
    self.class.run_job(CreateFacetJob.new(record))
  end

  def after_update(record)
    if record.deleted?
      self.class.run_job(RemoveFacetJob.new(record))
    else
      self.class.run_job(UpdateFacetJob.new(record))
    end
  end

  def after_destroy(record)
    self.class.run_job(RemoveFacetJob.new(record))
  end

  def self.run_job(job)
    job.delay.run
  end

  class AbstractJob < Struct.new(:record)
    # Split RIF-CS document into multiple documents representing a single facet
    def split_rifcs_document
      xml = record.to_rif_file rescue record.to_rif
      return [] if xml.nil?
      SplitDocumentWrapper.new(Nokogiri::XML::Reader(xml))
    end

    private

    class SplitDocumentWrapper < Struct.new(:reader)
      include Enumerable

      def each
        # Create a document to clone for the separate ones
        templateDoc = Nokogiri::XML::Document.new()
        reader.each do |node|
          # Ignore nodes which aren't elements - they're not important here
          next unless node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
          case node.name
          when 'registryObjects'
            populate_template_root(templateDoc, node)
          when 'registryObject'
            doc = templateDoc.clone
            doc.root << doc.fragment(node.outer_xml).children.first
            yield doc.to_xml
          end
        end
      end

      private

      # Populate root for our template document
      def populate_template_root(tmplDoc, node)
        namespaces = node.namespaces
        tmplDoc.root = tmplDoc.create_element(node.name, namespaces)
        node.attributes.each do |k,v|
          next if namespaces.key?(k)
          # Kludge to handle schemaLocation namespace disappearing
          case k
          when 'schemaLocation'
            tmplDoc.root.set_attribute('xsi:%s' % k, v)
          else
            tmplDoc.root.set_attribute(k, v)
          end
        end
      end

    end

  end

  class CreateFacetJob < AbstractJob
    def run
      split_rifcs_document.each do |xml|
        concept = Miletus::Merge::Concept.find_existing(xml)
        concept ||= Miletus::Merge::Concept.create()
        facet = concept.facets.create(:metadata => xml)
        if record.respond_to?(:facet_links)
          record.facet_links.create(:facet => facet)
        end
      end
    end
  end

  class UpdateFacetJob < AbstractJob
    def run
      existing_links = nil
      if record.respond_to?(:facet_links)
        existing_links = record.facet_links.all
      end
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
      unless existing_links.nil?
        # Remove links (and facets) for no longer present facets
        existing_links.reject{|l| facets.include?(l.facet)}.each do |l|
          existing_links.delete(l)
          l.destroy
        end
        # Refresh record to update the existing links
        record.reload
        # Create new links where necessary
        facets.each do |facet|
          unless existing_links.detect {|l| l.facet == facet}
            record.facet_links.create(:facet => facet)
          end
        end
        puts record.facet_links.inspect
      end
    end
  end

  class RemoveFacetJob < AbstractJob
    def run
      if record.respond_to?(:facet_links)
        record.facet_links.destroy_all
      else
        split_rifcs_document.each do |xml|
          facet = Miletus::Merge::Facet.find_existing(xml)
          facet.destroy unless facet.nil?
        end
      end
    end
  end

end
