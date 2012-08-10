
module Miletus::Harvest::SRU
  class Interface < ActiveRecord::Base

    self.table_name = 'sru_interfaces'

    attr_accessible :endpoint, :schema

    validates :endpoint, :presence => true
    validates_format_of :endpoint, :with => URI::regexp(%w(http https))
    validates_uniqueness_of :endpoint

    def lookup(value)
      client = SRU::Client.new(endpoint)

      # Create Common/Contextual Query Language (CQL) query

      # According to <http://www.loc.gov/standards/sru/specs/cql.html>:
      #
      # Double quotes enclosing a sequence of any characters except
      # double quote (unless preceded by backslash (\)). Backslash
      # escapes the character following it. The resultant value includes
      # all backslash characters except those releasing a double quote
      # (this allows other systems to interpret the backslash
      # character). The surrounding double quotes are not included.

      escaped_value = value.gsub('"', '\"')

      cql_query = "rec.identifier=\"#{escaped_value}\""

      # Search (returns a SRU::SearchRetrieveResponse object)

      records = client.search_retrieve(cql_query,
                              :maximumRecords => 2,
                              :resultSetTTL => 0,
                              :recordSchema => schema)

      num_records = records.number_of_records
      return nil if num_records.zero?
      raise DataError, "multiple matches found: #{value}" if num_records > 1
      # Get the contents of the first record
      Nokogiri::XML(records.first.to_s).root.children.first.to_s
    end

  end
end