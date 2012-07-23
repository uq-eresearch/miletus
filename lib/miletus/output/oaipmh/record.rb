require 'active_record'
require 'oai'
require 'time'

module Miletus
  module Output
    module OAIPMH

      class Record < ActiveRecord::Base

        @@schemas = {}

        attr_accessible :metadata

        self.table_name = 'output_oaipmh_records'

        def to_oai_dc
          return nil unless valid_rifcs?
          wrapper = RifCSToOaiDcWrapper.new(to_rif)
          OAI::Provider::Metadata::DublinCore.instance.encode(wrapper, wrapper)
        end

        def to_rif
          return nil unless valid_rifcs?
          XML::Document.string(metadata).tap do |xml|
            update_datetime(xml)
          end.to_s
        end

        def self.get_schema(schema)
          # Memoize fetching schemas
          @@schemas[schema] ||= self.do_get_schema(schema)
        end

        protected

        def update_datetime(rifcs_doc)
          types = %w{collection party activity service}
          pattern = types.map { |e| "//rif:#{e}"}.join(' | ')
          rifcs_doc.find(pattern, ns_decl).each do |e|
            e.attributes['dateModified'] = (updated_at || Time.now).iso8601
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

        def ns_decl(prefix = 'rif')
          "#{prefix}:#{RecordProvider.format(prefix).namespace}"
        end

        class RifCSToOaiDcWrapper

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

          def ns_decl(prefix = 'rif')
            "#{prefix}:#{RecordProvider.format(prefix).namespace}"
          end

        end

      end

    end
  end
end
