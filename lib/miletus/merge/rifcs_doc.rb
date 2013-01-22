module Miletus::Merge

  class RifcsDocs
    include Miletus::XPathNamespaceMixin

    attr_reader :docs

    def initialize(xml_strings = [])
      @docs = xml_strings.sort_by {|s| s.length }
                         .reverse
                         .map {|xml| RifcsDoc.create(xml)}
    end

    def content_from_nodes(xpath)
      docs.map{|doc| doc.xpath(xpath) # Get nodesets matching pattern
        }.map{|n| n.to_ary.map {|e| e.content.strip} # Get content values
        }.reduce(:|) or [] # Join arrays together, and handle nil case
    end

    def merge
      return nil if docs.empty?
      rifcs_doc = docs.first.clone
      rifcs_doc.merge_rifcs_elements(docs)
    end

  end

  class RifcsDoc < Nokogiri::XML::Document
    include Miletus::XPathNamespaceMixin

    def self.create(xml)
      instance = self.parse(xml) {|cfg| cfg.noblanks}
      # Strip leading and trailing whitespace,
      # as it's not meaningful in RIF-CS
      instance.xpath('//text()').each do |node|
        node.content = node.content.strip
      end
      instance
    end

    def sort_key
      name_order = ['primary', 'abbreviated', 'alternative', nil]
      names = xpath("//rif:name").to_ary.sort_by! do |n|
        name_order.index(n['type']) || 100 # Handle invalid name types
      end
      names.map{|n| sort_key_from_name_element(n)}.compact.first
    end

    def titles
      name_order = ['primary', 'abbreviated', 'alternative', nil]
      names = xpath("//rif:name").to_ary.sort_by! do |n|
        name_order.index(n['type'])
      end
      names.map{|n| title_from_name_element(n)}.uniq
    end

    def types
      n = at_xpath("//rif:registryObject/rif:*[last()]")
      n.nil? ? [] : [n.name, n['type']]
    end

    def group=(value)
      group_e = at_xpath("//rif:registryObject/@group")
      return false if group_e.nil?
      group_e.content = value
    end

    def key=(value)
      key_e = at_xpath("//rif:registryObject/rif:key")
      return false if key_e.nil?
      key_e.content = value
    end

    def translate_keys(dictionary)
      xpath("//rif:relatedObject/rif:key").each do |e|
        k = e.content.strip
        e.content = dictionary[k] if dictionary.key? k
      end
      # Ensure all related object elements are unique in content
      deduplicate_with_xpath("//rif:relatedObject")
    end

    def ensure_single_primary_name
      # Ensure there is only one primary name (and use the largest entry)
      first_primary_name, *other_primary_names = \
        xpath('//rif:name[@type="primary"]').to_ary.sort_by! do |n|
          -1 * n.to_xml.length # Reverse sort by length
        end
      if first_primary_name.nil?
        name_order = [nil, 'abbreviated', 'alternative']
        other_names = xpath('//rif:name').to_ary.sort_by! do |n|
          name_order.index(n['type'])
        end
        # No need to continue if there are no other candidates
        return if other_names.first.nil?
        # Otherwise, pick the first
        first_primary_name = other_names.first
        first_primary_name['type'] = 'primary' unless other_names.empty?
      else
        other_primary_names.each do |node|
          node['type'] = 'alternative'
        end
      end
      # Ensure primary name comes first (for really stupid RIF-CS consumers)
      first_name = at_xpath('//rif:name')
      first_name.before(first_primary_name) if first_name['type'] != 'primary'
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
      alt_parent = at_xpath("//rif:registryObject/rif:*[last()]")
      patterns.each do |pattern|
        # Get all identifier elements, unique in content
        merged_nodes = deduplicate_by_content(input_docs.map do |d|
          copy_nodes(d.xpath(pattern))
        end.reduce(:|))
        replace_all(xpath(pattern),
          Nokogiri::XML::NodeSet.new(self, merged_nodes),
          alt_parent)
      end
      ensure_single_primary_name
      ensure_description_exists
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

    def deduplicate_with_xpath(pattern)
      original_nodes = xpath(pattern)
      alt_parent = at_xpath("//rif:registryObject/rif:*[last()]")
      merged_nodes = \
        deduplicate_by_content(copy_nodes(original_nodes).to_ary)
      replace_all(original_nodes,
        Nokogiri::XML::NodeSet.new(self, merged_nodes),
        alt_parent)
    end

    def sort_key_from_name_element(name)
      sk = join_name_parts_in_order(name, %w[family given title suffix], '_')
      sk.upcase
    end

    def title_from_name_element(name)
      join_name_parts_in_order(name, %w[title given family suffix])
    end

    def ensure_description_exists
      if at_xpath("//rif:registryObject/rif:*[last()]/rif:description").nil?
        desc_parent = at_xpath("//rif:registryObject/rif:*[last()]")
        Nokogiri::XML::Builder.with(desc_parent) do |xml|
          xml.description(' ', :type => 'brief')
        end
      end
    end

    def join_name_parts_in_order(name, part_order, separator = ' ')
      found_parts = name.xpath("rif:namePart", ns_decl).to_ary
      parts = found_parts.select do |part|
        part_order.include?(part['type'])
      end
      if parts.empty?
        # No formal name parts, so just join them all in order
        found_parts.map{|e| e.content}.join(separator)
      else
        parts.sort_by! do |part|
          # In part order, but use original index to sort equal elements
          part_order.index(part['type']) * parts.length + parts.index(part)
        end
        parts.map{|e| e.content}.join(separator)
      end
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