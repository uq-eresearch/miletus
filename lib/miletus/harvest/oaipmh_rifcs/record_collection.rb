require 'uri'

module Miletus
  module Harvest
    module OAIPMH
      module RIFCS

        class RecordCollection < ActiveRecord::Base

          self.table_name = 'oaipmh_rifcs_record_collections'

          attr_accessible :endpoint
          attr_accessible :set

          validates :endpoint, :presence => true
          validates_format_of :endpoint, :with => URI::regexp(%w(http https))
          validates_uniqueness_of :endpoint

          has_many :records, :dependent => :destroy, :order => 'datestamp DESC'

          def set
            s = read_attribute(:set)
            s.to_s.empty? ? nil : s
          end

          def format
            'rif'
          end

          def get(identifier)
            saw(identifier)
            r = self.records.find_by_identifier(identifier)
            r.try(:to_oai) # Convert to OAI:Record unless nil
          end

          def add(oaiRecord)
            identifier = oaiRecord.header.identifier
            saw(identifier)
            self.records.find_or_initialize_by_identifier(identifier).tap do |r|
              r.datestamp = oaiRecord.header.datestamp
              r.metadata = oaiRecord.metadata
              r.save!()
            end
          end

          def remove(identifier, datestamp = DateTime.now())
            saw(identifier)
            r = self.records.find_by_identifier(identifier)
            return r if r.nil?
            r.datestamp = datestamp
            r.deleted = true
            r.save!()
          end

          def restrict_to
            @watch_list = Set.new
            yield
            self.records.each do |r|
              unless @watch_list.include? r.identifier
                r.destroy
              end
            end
            @watch_list = nil
          end

          def to_s
            "#{endpoint} (#{format})"
          end

          private

          def saw(identifier)
            # Use watchlist, or just throw away
            @watch_list << identifier unless @watch_list.nil?
          end

        end

      end
    end
  end
end