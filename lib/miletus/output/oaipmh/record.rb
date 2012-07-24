require 'active_record'
require 'oai'
require 'time'

module Miletus
  module Output
    module OAIPMH

      module NamespaceHelper
        def ns_decl
          # Convenience definition for XPath matching
          %w{ oai:http://www.openarchives.org/OAI/2.0/
              oaii:http://www.openarchives.org/OAI/2.0/oai-identifier
              dc:http://purl.org/dc/elements/1.1/
              oai_dc:http://www.openarchives.org/OAI/2.0/oai_dc/
              rif:http://ands.org.au/standards/rif-cs/registryObjects }
        end
        module_function :ns_decl
      end

      class Record < ActiveRecord::Base
        include NamespaceHelper

        validate :valid_rifcs?
        after_validation :clean_metadata

        @@schemas = {}

        attr_accessible :metadata

        self.table_name = 'output_oaipmh_records'

        def to_oai_dc
          return nil unless valid_rifcs?
          wrapper = RifCSToOaiDcWrapper.new(to_rif)
          OAI::Provider::Metadata::DublinCore.instance.encode(wrapper, wrapper)
        end

        def metadata=(xml)
          xml = XML::Document.string(xml).root.to_s
          write_attribute(:metadata, xml == "<xml/>" ? nil : xml)
        end

        def to_rif
          metadata
        end

        def self.get_schema(schema)
          # Memoize fetching schemas
          @@schemas[schema] ||= self.do_get_schema(schema)
        end

        protected

        def clean_metadata
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
            @doc.find('//rif:identifier', ns_decl).map do |identifier|
              identifier.content.strip
            end
          end

          def title
            get_name_parts.map do |parts|
              cond_tmpl(parts, [nil], "%s") or
                cond_tmpl(parts, %w{family given}, "%s, %s")
            end
          end

          def date
            @doc.find('//@dateModified', ns_decl).map {|d| d.value }
          end

          def description
            types = %w{collection party activity service}
            pattern = types.map { |e| "//rif:#{e}/rif:description"}.join(' | ')
            @doc.find(pattern, ns_decl).map {|d| d.content }
          end

          def rights
            @doc.find("//rif:rights/*", ns_decl).map {|d| d.content }
          end

          private

          def cond_tmpl(h, keys, tmpl)
            return nil unless keys.all? {|k| h.has_key?(k)}
            tmpl % h.values_at(*keys).map {|values| values.join(" ") }
          end

          def get_name_parts
            @doc.find("//rif:name", ns_decl).map do |e|
              e.find("rif:namePart", ns_decl).each_with_object({}) do |part, h|
                k = part.attributes['type'] ? part.attributes['type'] : nil
                (h[k] ||= []) << part.content.strip
              end
            end
          end

        end

      end

    end
  end
end
