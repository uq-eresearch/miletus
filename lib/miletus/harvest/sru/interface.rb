
module Miletus::Harvest::SRU
  class Interface < ActiveRecord::Base
    include Miletus::NamespaceHelper

    self.table_name = 'sru_interfaces'

    store :details, :accessors => [:schema, :exclude_xpaths]
    attr_accessible :endpoint, :schema, :exclude_xpaths

    validates :endpoint, :presence => true
    validates_format_of :endpoint, :with => URI::regexp(%w(http https))
    validates_uniqueness_of :endpoint

    def lookup_by_identifier(value)
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

      lookup("rec.identifier=\"#{escaped_value}\"")
    end

    private

    def lookup(cql_query)
      client = SRU::Client.new(endpoint)

      # Search (returns a SRU::SearchRetrieveResponse object)

      records = client.search_retrieve(cql_query,
                              :maximumRecords => 2,
                              :recordSchema => schema)

      num_records = records.number_of_records
      return nil if num_records.zero?
      raise DataError, "multiple matches found: #{value}" if num_records > 1

      # Get the contents of the first record
      doc = Nokogiri::XML(records.first.to_s).root.children.first
      doc = filter_nodes(doc) unless exclude_xpaths.nil?
      doc.to_s
    end

    def filter_nodes(doc)
      exclude_xpaths.each do |p|
        doc.xpath(p, ns_decl).tap {|matches| matches.each { |n| n.remove } }
      end
      doc
    end

  end
end