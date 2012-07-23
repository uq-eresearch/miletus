require 'active_record'
require 'oai'

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
          valid_rifcs? ? metadata : nil
        end

        def self.get_schema(schema)
          # Memoize fetching schemas
          @@schemas[schema] ||= self.do_get_schema(schema)
        end

        protected

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

          def initialize(rifcs)
            @doc = XML::Document.string(rifcs)
          end

          def identifier
            identifier = @doc.find_first('//rif:identifier', ns_decl)
            identifier and identifier.content.strip
          end

          def title
            cond_tmpl(get_name_parts, [nil], "%s") or
              cond_tmpl(get_name_parts, %w{family given}, "%s, %s")
          end

          def date
            d = @doc.find_first('//@dateModified', ns_decl)
            d and d.value
          end

          private

          def cond_tmpl(h, keys, tmpl)
            keys.all? {|k| h.has_key?(k)} ? tmpl % h.values_at(*keys) : nil
          end

          def get_name_parts
            @doc.find("//rif:name/rif:namePart",
                      ns_decl).each_with_object({}) do |part, h|
              k = part.attributes['type'] ? part.attributes['type'] : nil
              h[k] = part.content.strip
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
