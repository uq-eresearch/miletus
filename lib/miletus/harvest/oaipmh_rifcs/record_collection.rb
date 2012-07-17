require 'active_record'
require 'uri'
require 'miletus/harvest/oaipmh_rifcs/record'

module Miletus
  module Harvest
    module OAIPMH
      module RIFCS

        class RecordCollection < ActiveRecord::Base

          self.table_name = 'oaipmh_rifcs_record_collections'

          validates :format, :endpoint, :presence => true
          validates_format_of :endpoint, :with => URI::regexp(%w(http https))
          validates_uniqueness_of :endpoint

          has_many :records, :dependent => :destroy, :order => 'datestamp DESC'

          def format
            'rif'
          end

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

          def to_s
            "#{endpoint} (#{format})"
          end

        end

      end
    end
  end
end