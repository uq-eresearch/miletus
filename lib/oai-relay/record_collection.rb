require 'active_record'
require 'uri'

class RecordCollection < ActiveRecord::Base

  validates :format, :endpoint, :presence => true
  validates_format_of :endpoint, :with => URI::regexp(%w(http https))
  validates_uniqueness_of :format, :endpoint

  has_many :records, :dependent => :destroy

  def get(identifier)
    self.records.find_by_identifier(identifier)
  end

  def add(oaiRecord)
    identifier = oaiRecord.header.identifier
    r = self.records.find_or_initialize_by_identifier(identifier)
    r.datestamp = oaiRecord.header.datestamp
    r.metadata = oaiRecord.metadata
    r.save()
  end

  def remove(identifier)
    # TODO: Implement "remove" method
  end

end

class Record < ActiveRecord::Base

  belongs_to :record_collection

  # These fields should exist
  validates :identifier, :datestamp, :metadata, :presence => true

  # Identifier should be unique inside a collection
  validates :identifier, :uniqueness => { :scope => :record_collection_id }

end