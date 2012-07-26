# Un-ruby pattern required by lib-xml `find` calls:
# http://libxml.rubyforge.org/rdoc/classes/LibXML/XML/Document.html#M000475
#
# Please don't refactor it away unless you like segfaults!

module Miletus::Output::OAIPMH

  class Record < ActiveRecord::Base
    include NamespaceHelper

    self.table_name = 'output_oaipmh_records'

    attr_accessible :metadata
    has_many :indexed_attributes,
      :class_name => 'Miletus::Output::OAIPMH::IndexedAttribute',
      :foreign_key => 'record_id',
      :autosave => true

    validate :valid_rifcs?
    after_validation :clean_metadata

    @@schemas = {}

    def to_oai_dc
      return nil unless valid_rifcs?
      wrapper = RifCSToOaiDcWrapper.new(to_rif)
      OAI::Provider::Metadata::DublinCore.instance.encode(wrapper, wrapper)
    end

    def metadata=(xml)
      if xml.nil? or xml == ''
        write_attribute(:metadata, '')
      else
        doc = XML::Document.string(xml)
        key_nodes = doc.find('//rif:key', ns_decl)
        update_indexed_attributes('rifcs_key',
          key_nodes.map { |e| e.content.strip })
        xml = doc.root.to_s
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
      xml = XML::Document.string(read_attribute(:metadata)).tap do |xml|
          translate_old_elements(xml)
          update_datetime(xml)
        end.root.to_s
      write_attribute(:metadata, xml)
    end

    def update_datetime(rifcs_doc)
      types = %w{collection party activity service}
      pattern = types.map { |e| "//rif:#{e}"}.join(' | ')
      rifcs_doc.find(pattern, ns_decl).each do |e|
        e.attributes['dateModified'] = Time.now.utc.iso8601
      end
    end

    def translate_old_elements(rifcs_doc)
      pattern = ['rights', 'accessRights'].map do |t|
        "//rif:description[@type=\"%s\"]" % t
      end.join("|")
      rifcs_doc.find(pattern, ns_decl).each do |e|
        rights = e.parent.find_first("rif:rights", ns_decl)
        ns = e.parent.namespaces.default
        rights ||= XML::Node.new('rights', '', ns).tap do |er|
          e.parent << er
        end

        case e.attributes['type']
        when 'rights'
          rights << XML::Node.new('rightsStatement', e.content, ns)
        when 'accessRights'
          rights << XML::Node.new('accessRights', e.content, ns)
        end
        e.remove!
      end
    end

    def valid_rifcs?
      begin
        schema = self.class.get_schema('rif')
        XML::Document.string(metadata).validate_schema(schema)
      rescue TypeError, LibXML::XML::Error
        false
      end
    end

    def self.do_get_schema(schema)
      require File.join(File.dirname(__FILE__), 'record_provider')
      LibXML::XML::Schema.new(RecordProvider.format(schema).schema)
    end

    class RifCSToOaiDcWrapper
      include NamespaceHelper

      def initialize(rifcs)
        @doc = XML::Document.string(rifcs)
      end

      def identifier
        nodes = @doc.find('//rif:identifier', ns_decl)
        nodes.map { |identifier| identifier.content.strip }
      end

      def title
        get_name_parts.map do |parts|
          cond_tmpl(parts, [nil], "%s") or
            cond_tmpl(parts, %w{family given}, "%s, %s")
        end
      end

      def date
        nodes = @doc.find('//@dateModified', ns_decl)
        nodes.map {|d| d.value }
      end

      def description
        types = %w{collection party activity service}
        pattern = types.map { |e| "//rif:#{e}/rif:description"}.join(' | ')
        nodes = @doc.find(pattern, ns_decl)
        nodes.map {|d| d.content }
      end

      def rights
        nodes = @doc.find("//rif:rights/*", ns_decl)
        nodes.map {|d| d.content }
      end

      private

      def cond_tmpl(h, keys, tmpl)
        return nil unless keys.all? {|k| h.has_key?(k)}
        tmpl % h.values_at(*keys).map {|values| values.join(" ") }
      end

      def get_name_parts
        nodes = @doc.find("//rif:name", ns_decl)
        nodes.map do |e|
          e_nodes = e.find("rif:namePart", ns_decl)
          e_nodes.each_with_object({}) do |part, h|
            k = part.attributes['type'] ? part.attributes['type'] : nil
            (h[k] ||= []) << part.content.strip
          end
        end
      end

    end

  end

end
