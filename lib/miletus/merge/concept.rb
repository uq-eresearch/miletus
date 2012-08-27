require 'equivalent-xml'
require 'set'

module Miletus::Merge

  class Concept < ActiveRecord::Base
    extend Miletus::NamespaceHelper
    include Miletus::NamespaceHelper

    self.table_name = 'merge_concepts'

    has_many :facets, :dependent => :destroy, :order => 'updated_at DESC'
    has_many :indexed_attributes,
      :dependent => :destroy, :order => [:key, :value]

    def group
      if ENV.has_key? 'CONCEPT_GROUP'
        ENV['CONCEPT_GROUP']
      else
        key_prefix
      end
    end

    def key
      "%s%d" % [key_prefix, id]
    end

    def self.find_existing(xml)
      id_nodes = Nokogiri::XML(xml).xpath(
        '//rif:identifier', ns_decl)
      existing = id_nodes.map do |e|
        joins(:indexed_attributes).where(
          IndexedAttribute.table_name.to_sym => {
            :key => 'identifier',
            :value => e.content.strip
          }
        ).pluck(:concept_id)
      end.flatten
      return nil if existing.empty?
      find_by_id(existing.first)
    end

    def to_rif
      input_docs = rifcs_facets
      return nil if input_docs.empty?
      rifcs_doc = input_docs.first.clone
      rifcs_doc.merge_rifcs_elements(input_docs)
      rifcs_doc.group = group
      rifcs_doc.key = key
      rifcs_doc.translate_keys(related_key_dictionary)
      rifcs_doc.root.to_xml(:indent => 2)
    end

    def update_indexed_attributes_from_facet_rifcs
      input_docs = rifcs_facets
      update_indexed_attributes('identifier',
        content_from_nodes(input_docs,
          '//rif:registryObject/rif:*/rif:identifier'))
      update_indexed_attributes('relatedKey',
        content_from_nodes(input_docs, '//rif:relatedObject/rif:key'))
    end

    def related_concepts
      inbound_related_concepts.to_set | outbound_related_concepts.to_set
    end

    def to_s
      "%s incorporating %s" % [key, facets.pluck(:key).inspect]
    end

    private

    def related_key_dictionary
      Hash[*outbound_related_concepts.map do |c|
        c.facets.map {|f| [f.key, c.key] }
      end.flatten]
    end

    def key_prefix
      if ENV.has_key? 'CONCEPT_KEY_PREFIX'
        ENV['CONCEPT_KEY_PREFIX']
      else
        require 'socket'
        'urn:%s:' % Socket.gethostname
      end
    end

    def inbound_related_concepts
      in_keys = facets.pluck(:key)
      return [] if in_keys.compact.empty?
      self.class.joins(:indexed_attributes).where(
          ["#{tn(:indexed_attributes)}.key = 'relatedKey'",
           "#{tn(:indexed_attributes)}.value IN (?)"].join(' AND '),
          in_keys
        )
    end

    def outbound_related_concepts
      out_keys = indexed_attributes.where(:key => 'relatedKey').pluck(:value)
      return [] if out_keys.compact.empty?
      self.class.joins(:facets).where(
          "#{tn(:facets)}.key in (?)", out_keys
        )
    end

    def tn(relation)
      self.class.reflect_on_association(relation).klass.table_name
    end

    def content_from_nodes(docs, xpath)
      docs.map{|doc| doc.xpath(xpath, ns_decl) # Get nodesets matching pattern
        }.map{|n| n.to_ary.map {|e| e.content.strip} # Get content values
        }.reduce(:|) or [] # Join arrays together, and handle nil case
    end

    def rifcs_facets
      facets.order(:created_at).map {|f| f.to_rif}.reject {|xml| xml.nil?}\
        .map {|xml| RifCsDoc.create(xml)}
    end

    def update_indexed_attributes(key, new_values)
      self.transaction do
        current_values = indexed_attributes.where(:key => key).select(:value)
        (new_values - current_values).each do |v|
          indexed_attributes.find_or_create_by_key_and_value(key, v)
        end
        indexed_attributes.where(:id => current_values - new_values).delete_all
      end
    end

    class RifCsDoc < Nokogiri::XML::Document
      include Miletus::NamespaceHelper

      def self.create(xml)
        instance = self.parse(xml) {|cfg| cfg.noblanks}
        # Strip leading and trailing whitespace,
        # as it's not meaningful in RIF-CS
        instance.xpath('//text()').each do |node|
          node.content = node.content.strip
        end
        instance
      end

      def group=(value)
        group_e = at_xpath("//rif:registryObject/@group", ns_decl)
        return false if group_e.nil?
        group_e.content = value
      end

      def key=(value)
        key_e = at_xpath("//rif:registryObject/rif:key", ns_decl)
        return false if key_e.nil?
        key_e.content = value
      end

      def translate_keys(dictionary)
        xpath("//rif:relatedObject/rif:key", ns_decl).each do |e|
          k = e.content.strip
          e.content = dictionary[k] if dictionary.key? k
        end
      end

      def merge_rifcs_elements(input_docs)
        patterns = [
          "//rif:registryObject/rif:*/rif:identifier",
          "//rif:name",
          "//rif:location"]
        alt_parent = at_xpath("//rif:registryObject/rif:*[last()]", ns_decl)
        patterns.each do |pattern|
          # Get all identifier elements, unique in content
          merged_nodes = deduplicate_by_content(input_docs.map do |d|
            copy_nodes(d.xpath(pattern, ns_decl))
          end.reduce(:|))
          replace_all(xpath(pattern, ns_decl),
            Nokogiri::XML::NodeSet.new(self, merged_nodes),
            alt_parent)
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

      def replace_all(orig_tags, tags, alt_parent)
        orig_tags[1..-1].each {|m| m.remove} if orig_tags.count > 1
        if orig_tags.first.nil?
          alt_parent << tags
        else
          orig_tags.first.swap(tags)
        end
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