require 'oai'
require 'active_record'
require 'xml/libxml'

module Miletus
  module Harvest
    module OAIPMH
      module RIFCS

        class Record < ActiveRecord::Base

          self.table_name = 'oaipmh_rifcs_records'

          class OaiHeader < OAI::Header
            def initialize
            end
          end

          class OaiRecord < OAI::Record
            def initialize
            end
          end

          attr_accessible :identifier, :datestamp, :metadata, :deleted

          belongs_to :record_collection,
            :class_name => 'Miletus::Harvest::OAIPMH::RIFCS::RecordCollection',
            :foreign_key => 'record_collection_id'

          # These fields should exist
          validates :identifier, :datestamp, :metadata, :presence => true

          # Identifier should be unique inside a collection
          validates :identifier,
            :uniqueness => { :scope => :record_collection_id }

          def self.from_oai(oaiRecord)
            self.new(
              :identifier => oaiRecord.header.identifier,
              :datestamp => oaiRecord.header.datestamp,
              :metadata => oaiRecord.metadata,
              :deleted => oaiRecord.header.deleted?)
          end

          def metadata=(metadata)
            write_attribute(:metadata, xml_obj_to_str(metadata))
          end

          def metadata
            xml_str_to_obj(read_attribute(:metadata))
          end

          def to_oai
            OaiRecord.new().tap do |oaiRecord|
              oaiRecord.header = oai_header
              oaiRecord.metadata = metadata
            end
          end

          def to_rif
            metadata.children.map { |obj|
              xml_obj_to_str(obj)
            }.join("\n")
          end

          private

          def xml_str_to_obj(xml)
            begin
              XML::Document.string(xml).root
            rescue ArgumentError
              nil
            end
          end

          def xml_obj_to_str(obj)
            case obj.class.name
              when 'LibXML::XML::Node'
                XML::Document.new().try{|d| d.root = d.import(obj) }.to_s
              when 'REXML::Element'
                REXML::Document.new().try{|d| d.add(obj) }.to_s
              else
                obj.to_s
            end
          end


          def oai_header
            OaiHeader.new().tap do |oaiHeader|
              oaiHeader.identifier = self.identifier
              oaiHeader.datestamp = self.datestamp
              oaiHeader.status = self.deleted? ? 'deleted' : ''
            end
          end

        end

      end
    end
  end
end