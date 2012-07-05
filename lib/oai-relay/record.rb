require 'oai'
require 'active_record'

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
      :metadata => oaiRecord.metadata)
  end

  def _oai_header
    OaiHeader.new().tap do |oaiHeader|
      oaiHeader.identifier = self.identifier
      oaiHeader.datestamp = self.datestamp
    end
  end

  def to_oai
    OaiRecord.new().tap do |oaiRecord|
      oaiRecord.header = self._oai_header
      oaiRecord.metadata = self.metadata
    end
  end

end