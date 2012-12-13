
module Miletus::Harvest::SRU
  class Interface < ActiveRecord::Base
    include Miletus::NamespaceHelper

    self.table_name = 'sru_interfaces'

    store :details, :accessors => [:schema, :exclude_xpaths, :limit_to_types]
    attr_accessible :endpoint, :schema, :exclude_xpaths, :exclude_xpaths_string

    validates :endpoint, :presence => true
    validates :schema, :presence => true
    validates_format_of :endpoint, :with => URI::regexp(%w(http https))
    validates_uniqueness_of :endpoint

    def exclude_xpaths_string
      self.exclude_xpaths.try(:join, "\n") || ''
    end

    def exclude_xpaths_string=(exclude_xpaths_string)
      self.exclude_xpaths = exclude_xpaths_string.split("\n").map(&:strip)
    end

    def lookup_by_identifier(value)
      # Handle nil identifiers that might leak through
      return nil if value.nil?

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

    def suitable_type?(type)
      return true if limit_to_types.nil?
      limit_to_types.include?(type)
    end

    private

    def lookup(cql_query)
      begin
        client = SRU::Client.new(endpoint)
        # Search (returns a SRU::SearchRetrieveResponse object)
        records = client.search_retrieve(cql_query,
                                :maximumRecords => 2,
                                :recordSchema => schema)
      rescue Exception => e
        Rails.logger.error "Failed to look up #{self}: #{e.message}"
        return nil
      end

      num_records = records.number_of_records
      return nil if num_records.zero?
      raise Error, "multiple matches found: #{value}" if num_records > 1

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

    def to_s
      "SRU interface @ " + self.endpoint
    end

  end
end