require 'nokogiri'

module Miletus::Harvest::OAIPMH::RIFCS

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
    has_many :facet_links, :as => :harvest_record,
      :class_name => 'Miletus::Harvest::FacetLink'

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

    def to_oai
      OaiRecord.new().tap do |oaiRecord|
        oaiRecord.header = oai_header
        oaiRecord.metadata = XML::Document.string(metadata).root rescue nil
      end
    end

    def to_rif
      doc = Nokogiri::XML::Document.parse(metadata)
      doc.root.children.map { |obj| obj.to_s }.join("\n")
    end

    private

    def xml_obj_to_str(obj)
      case obj.class.name
        when 'LibXML::XML::Node'
          XML::Document.new().try{|d| d.root = d.import(obj) }.to_s
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