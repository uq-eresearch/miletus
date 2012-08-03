# Un-ruby pattern required by lib-xml `find` calls:
# http://libxml.rubyforge.org/rdoc/classes/LibXML/XML/Document.html#M000475
#
# Please don't refactor it away unless you like segfaults!
require 'nokogiri'

module Miletus::Output::OAIPMH

  class Record < ActiveRecord::Base
    include Miletus::NamespaceHelper

    self.table_name = 'output_oaipmh_records'

    attr_accessible :metadata
    belongs_to :underlying_concept,
      :class_name => 'Miletus::Merge::Concept'

    validate :valid_rifcs?
    after_validation :clean_metadata

    @@schemas = {}

    def to_oai_dc
      return nil unless valid_rifcs?
      wrapper = RifCSToOaiDcWrapper.new(to_rif)
      OAI::Provider::Metadata::DublinCore.instance.encode(wrapper, wrapper)
    end

    def deleted?
      underlying_concept.nil? ? false : underlying_concept.facets.empty?
    end

    def metadata=(xml)
      if xml.nil? or xml == ''
        write_attribute(:metadata, '')
      else
        xml = Nokogiri::XML(xml).root.to_s
        write_attribute(:metadata, xml == "<xml/>" ? nil : xml)
      end
    end

    def to_rif
      metadata
    end

    def self.get_schema(schema)
      # Memoize fetching schemas
      @@schemas[schema] ||= self.do_get_schema(schema)
    end

    protected

    def update_indexed_attributes(key, values)
      if indexed_attributes.find_by_key(key)
        current = indexed_attributes.where(:key => key).map {|o| o.value}
        created = values - current
        deleted = current - values
        indexed_attributes.where(:key => key, :value => deleted).delete_all
      else
        created = values
      end
      created.each do |value|
        indexed_attributes.build(:key => key, :value => value)
      end
    end

    def clean_metadata
      return if read_attribute(:metadata).nil?
      xml = Nokogiri::XML(read_attribute(:metadata)).tap do |xml|
          translate_old_elements(xml)
          update_datetime(xml)
        end.root.to_s
      write_attribute(:metadata, xml)
    end

    def update_datetime(rifcs_doc)
      types = %w{collection party activity service}
      pattern = types.map { |e| "//rif:#{e}"}.join(' | ')
      rifcs_doc.xpath(pattern, ns_decl).each do |e|
        e['dateModified'] = Time.now.utc.iso8601
      end
    end

    def translate_old_elements(rifcs_doc)
      types = {'rights' => 'rightsStatement', 'accessRights' => 'accessRights'}
      # Assemble xpath search pattern
      pattern = types.keys.map do |t|
          "//rif:description[@type=\"%s\"]" % t
        end.join("|")
      # For those description elements we can translate...
      rifcs_doc.xpath(pattern, ns_decl).each do |e|
        # Get the rights element or create it if necessary
        rights = e.parent.at_xpath("rif:rights", ns_decl)
        ns = e.parent.namespaces.default
        rights ||= Nokogiri::XML::Node.new('rights', rifcs_doc).tap do |er|
          e.parent << er
        end
        # Create new element based on attribute name and insert it
        Nokogiri::XML::Node.new(types[e['type'].to_s], rifcs_doc).tap do |node|
          node.content = e.content
          rights << node
          e.remove
        end
      end
    end

    def valid_rifcs?
      begin
        self.class.get_schema('rif').validate(Nokogiri::XML(metadata)).empty?
      rescue TypeError
        false
      end
    end

    def self.do_get_schema(schema)
      require File.join(File.dirname(__FILE__), 'record_provider')
      require 'open-uri'
      schema_loc = RecordProvider.format(schema).schema
      schema_doc = Nokogiri::XML(open(schema_loc), url = schema_loc)
      Nokogiri::XML::Schema.from_document(schema_doc)
    end

    class RifCSToOaiDcWrapper
      include Miletus::NamespaceHelper

      def initialize(rifcs)
        @doc = Nokogiri::XML(rifcs)
      end

      def identifier
        nodes = @doc.xpath('//rif:identifier', ns_decl)
        nodes.map { |identifier| identifier.content.strip }
      end

      def title
        get_name_parts.map do |parts|
          cond_tmpl(parts, [nil], "%s") or
            cond_tmpl(parts, %w{family given}, "%s, %s")
        end
      end

      def date
        @doc.xpath('//@dateModified', ns_decl).map {|d| d.value }
      end

      def description
        types = %w{collection party activity service}
        pattern = types.map { |e| "//rif:#{e}/rif:description"}.join(' | ')
        @doc.xpath(pattern, ns_decl).map {|d| d.content }
      end

      def rights
        @doc.xpath("//rif:rights/*", ns_decl).map {|d| d.content }
      end

      private

      def cond_tmpl(h, keys, tmpl)
        return nil unless keys.all? {|k| h.has_key?(k) }
        tmpl % h.values_at(*keys).map {|values| values.join(" ") }
      end

      def get_name_parts
        @doc.xpath("//rif:name", ns_decl).map do |e|
          e.xpath("rif:namePart", ns_decl).each_with_object({}) do |part, h|
            k = part.key?('type') ? part['type'].to_s : nil
            (h[k] ||= []) << part.content.strip
          end
        end
      end

    end

  end

end
