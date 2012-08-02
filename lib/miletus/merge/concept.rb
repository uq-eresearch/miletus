require 'equivalent-xml'

module Miletus::Merge

  class Concept < ActiveRecord::Base

    self.table_name = 'merge_concepts'

    has_many :facets, :dependent => :destroy, :order => 'updated_at DESC'
    has_many :indexed_attributes,
      :dependent => :destroy, :order => [:key, :value]

    def to_rif
      input_docs = facets.map {|f| f.to_rif}.reject {|xml| xml.nil?}\
        .map {|xml| RifCsDoc.create(xml)}
      return nil if input_docs.empty?
      rifcs_doc = input_docs.first.clone
      rifcs_doc.merge_rifcs_elements(input_docs)
      rifcs_doc.root.to_xml(:indent => 2)
    end

    class RifCsDoc < Nokogiri::XML::Document
      include Miletus::NamespaceHelper

      def self.create(xml)
        instance = self.parse(xml) {|cfg| cfg.noblanks}
        instance.xpath('//text()').each do |node|
          node.content = node.content.strip
        end
        instance
      end

      def merge_rifcs_elements(input_docs)
        ["//rif:identifier", "//rif:name", "//rif:location"].each do |pattern|
          # Get all identifier elements, unique in content
          merged_nodes = deduplicate_by_content(input_docs.map do |d|
            copy_nodes(d.xpath(pattern, ns_decl))
          end.reduce(:|))
          replace_all(xpath(pattern, ns_decl),
            Nokogiri::XML::NodeSet.new(self, merged_nodes))
        end
        self
      end

      private

      def copy_nodes(nodeset)
        nodeset.to_ary.map { |n| n = n.dup }.map do |n|
          n.default_namespace = n.namespace
          n
        end
      end

      def deduplicate_by_content(nodes)
        nodes.uniq {|e| EquivalentWrapper.new(e) }
      end

      def replace_all(orig_tags, tags)
        orig_tags[1..-1].each {|m| m.remove} if orig_tags.count > 1
        orig_tags.first.swap(tags)
      end

      class EquivalentWrapper < Struct.new(:node)
        def hash
          node.name.hash
        end

        def ==(other)
          EquivalentXml.equivalent?(node, other.node, opts = {
            :element_order => false,
            :normalize_whitespace => true
          })
        end

        def eql?(other)
          self == other
        end

      end

    end



  end

end