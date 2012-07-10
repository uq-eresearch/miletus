require 'oai'
require 'active_record'
require 'xml/libxml'

class Record < ActiveRecord::Base

  class OaiHeader < OAI::Header
    def initialize
    end
  end

  class OaiRecord < OAI::Record
    def initialize
    end
  end

  belongs_to :record_collection

  # These fields should exist
  validates :identifier, :datestamp, :metadata, :presence => true

  # Identifier should be unique inside a collection
  validates :identifier, :uniqueness => { :scope => :record_collection_id }

  def self.from_oai(oaiRecord)
    Record.new(
      :identifier => oaiRecord.header.identifier,
      :datestamp => oaiRecord.header.datestamp,
      :metadata => oaiRecord.metadata,
      :deleted => oaiRecord.header.deleted?)
  end

  def metadata=(metadata)
    write_attribute(:metadata, _xml_obj_to_str(metadata))
  end

  def metadata
    _xml_str_to_obj(read_attribute(:metadata))
  end

  def _xml_str_to_obj(xml)
    begin
      XML::Document.string(xml).root
    rescue ArgumentError
      nil
    end
  end

  def _xml_obj_to_str(obj)
    case obj.class.name
      when 'LibXML::XML::Node'
        XML::Document.new().try{|d| d.root = d.import(obj) }.to_s
      when 'REXML::Element'
        REXML::Document.new().try{|d| d.add(obj) }.to_s
      else
        obj.to_s
    end
  end


  def _oai_header
    OaiHeader.new().tap do |oaiHeader|
      oaiHeader.identifier = self.identifier
      oaiHeader.datestamp = self.datestamp
      oaiHeader.status = self.deleted? ? 'deleted' : ''
    end
  end

  def to_oai
    OaiRecord.new().tap do |oaiRecord|
      oaiRecord.header = self._oai_header
      oaiRecord.metadata = self.metadata
    end
  end

end