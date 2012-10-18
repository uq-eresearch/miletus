module Miletus::Merge
  class RifcsDoc < Nokogiri::XML::Document
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

    def titles
      name_order = ['primary', 'abbreviated', 'alternative', nil]
      names = xpath("//rif:name", ns_decl).to_ary.sort_by! do |n|
        name_order.index(n['type'])
      end
      names.map{|n| title_from_name_element(n)}.uniq
    end

    def types
      n = at_xpath("//rif:registryObject/rif:*[last()]", ns_decl)
      n.nil? ? [] : [n.name, n['type']]
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

    def ensure_single_primary_name
      # Ensure there is only one primary name (and use the largest entry)
      first_primary_name, *other_primary_names = \
        xpath('//rif:name[@type="primary"]', ns_decl).to_ary.sort_by! do |n|
          -1 * n.to_xml.length # Reverse sort by length
        end
      if first_primary_name.nil?
        name_order = [nil, 'abbreviated', 'alternative']
        other_names = xpath('//rif:name', ns_decl).to_ary.sort_by! do |n|
          name_order.index(n['type'])
        end
        other_names.first['type'] = 'primary' unless other_names.empty?
      else
        other_primary_names.each do |node|
          node['type'] = 'alternative'
        end
      end
    end

    def merge_rifcs_elements(input_docs)
      patterns = %w[
        //rif:registryObject/rif:*/rif:identifier
        //rif:name
        //rif:description
        //rif:location
        //rif:coverage
        //rif:registryObject/rif:*/rif:relatedObject
        //rif:relatedInfo
        //rif:rights
      ]
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
      ensure_single_primary_name
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

    def title_from_name_element(name)
      part_order = ['title', 'given', 'family', 'suffix', nil]
      parts = name.xpath("rif:namePart", ns_decl).to_ary
      parts.delete_if { |part| not part_order.include?(part['type']) }
      parts.sort_by! do |part|
        # In part order, but use original index to sort equal elements
        part_order.index(part['type']) * parts.length + parts.index(part)
      end
      parts.map{|e| e.content}.join(" ")
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