require 'active_record'
require 'oai'

require File.join(File.dirname(__FILE__), 'record_provider')

module Miletus
  module Output
    module OAIPMH

      class Record < ActiveRecord::Base

        @@schemas = {}

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
          LibXML::XML::Schema.new(RecordProvider.format(schema).schema)
        end

        class RifCSToOaiDcWrapper

          def initialize(rifcs)
            @doc = XML::Document.string(rifcs)
          end

          def identifier
            @doc.find_first('//rif:identifier', ns_decl).content.strip
          end

          def title
            "#{get_name_part('family')}, #{get_name_part('given')}"
          end

          def date
            @doc.find_first('//@dateModified', ns_decl).value
          end

          private

          def get_name_part(type)
            @doc.find_first(
              "//rif:name/rif:namePart[@type='#{type}']",
              ns_decl).content.strip
          end

          def ns_decl
            "rif:#{RecordProvider.format('rif').namespace}"
          end

        end

      end

    end
  end
end
