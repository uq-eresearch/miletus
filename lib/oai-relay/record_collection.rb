require 'active_record'
require 'uri'
require 'oai-relay/record'

class RecordCollection < ActiveRecord::Base

  validates :format, :endpoint, :presence => true
  validates_format_of :endpoint, :with => URI::regexp(%w(http https))
  validates_uniqueness_of :format, :endpoint

  has_many :records, :dependent => :destroy

  def get(identifier)
    r = self.records.find_by_identifier(identifier)
    r && r.to_oai # Convert to OAI:Record unless nil
  end

  def add(oaiRecord)
    identifier = oaiRecord.header.identifier
    self.records.find_or_initialize_by_identifier(identifier).tap do |r|
      r.datestamp = oaiRecord.header.datestamp
      r.metadata = oaiRecord.metadata
      r.save!()
    end
  end

  def remove(identifier, datestamp = DateTime.now())
    r = self.records.find_by_identifier(identifier)
    return r if r.nil?
    r.datestamp = datestamp
    r.deleted = true
    r.save!()
  end

end