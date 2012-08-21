#!/usr/bin/env ruby
#
# Obtains an NLA Party Identifier by searching for the identifer
# of a party record that was harvested by Trove.
#
# Copyright (C) 2012, The University of Queensland.
#----------------------------------------------------------------

require 'sru'

# Open up the SRU::SearchResponse class to add a method for parsing
# RIF-CS identifiers. This needs to be a method of that class, so that
# it can use the custom XPath functions that came with SRU. Those
# XPath functions take into account that the SRU module can use
# different XML parsers.

module SRU
  class SearchResponse < Response

    # Returns all the RIF-CS identifiers as a hash. The keys
    # of the hash are the "type" and the values of the hash are
    # arrays of one or more identifier values.

    def rifcs_identifiers(record)

      @namespaces['r'] =
        'http://ands.org.au/standards/rif-cs/registryObjects'

      # The record is:
      # <recordData>
      #   <registryObjects>
      #     <registryObject>
      #       ...
      #       <party>
      #         ...
      #       </party>
      #     </registryObject>
      #   </registryObjects>
      # </recordData>

      result = {}

      xpath_all(record,
            'r:registryObjects/r:registryObject/r:party/r:identifier',
            @namespaces).each do |id|

        # Extract the type and identifier value

        type = get_attribute(id, 'type').to_s
        value = xpath(id, '.', @namespaces)

        # Store it in the result

        if ! result.has_key?(type)
          result[type] = []
        end
        result[type] << value

      end

      return result
    end

    # Returns the RIF-CS registryObject key as a string.

    def rifcs_key(record)

      @namespaces['r'] =
        'http://ands.org.au/standards/rif-cs/registryObjects'

      return xpath(record, 'r:registryObjects/r:registryObject/r:key',
                   @namespaces)
    end

  end
end

#----------------------------------------------------------------

class TroveSRU

  # The NLA Party Infrastructure APIs are documented at:
  # https://wiki.nla.gov.au/display/ARDCPIP/Party+Infrastructure+APIs

  # The RIF-CS identifier type for a NLA Party Identifier.

  NLA_PARTY_ID_TYPE = 'AU-ANL:PEAU'

  # The URL for Trove's people and organisations SRU interface.

  SRU_URL_PRODUCTION = 'http://www.nla.gov.au/apps/srw/search/peopleaustralia'
  SRU_URL_TEST = 'http://www-test.nla.gov.au/apps/srw/search/peopleaustralia'

  # Schema value for RIF-CS. Passed to the SRU searchRetrive operation
  # as the recordSchema parameter to indicate that the results must
  # be returned in the RIF-CS format.

  RIFCS_SCHEMA = 'http://ands.org.au/standards/rif-cs/registryObjects'

  # Exception that indicates our understanding or assumptions
  # about the data in NLA Trove is incorrect.
  #
  # If this exception is raised, it should be treated as an internal
  # error that requires a programmer to investigate and resolve.

  class DataError < StandardError
  end

  # Obtain the NLA Party Identifier corresponding to a party record
  # that was uploaded to Trove.
  #
  # If nil is returned, the party record was not found in Trove, which
  # could mean it has not been harvested or has failed the automatic
  # matching algorithm and is awaiting manual processing in the
  # Trove Identities Manager (TIM).
  #
  # This implementation assumes the NLA Party Identifier is the value
  # of the registryObject "key". Although copies of it also appear as
  # a RIF-CS identifier and as an electronic address.
  #
  # *type* - the identifier type attribute. Nil if it doesn't matter.
  #
  # *value* - the identifier value
  #
  # *use_test* - query the production Trove or the test Trove
  #
  # Returns the NLA Party Identifer as a string, or {nil} if not found
  #
  # Raises DataError if an internal error occurs

  def self.lookup_nla_id(type, value, use_test = nil)

    # Create Common/Contextual Query Language (CQL) query

    # According to <http://www.loc.gov/standards/sru/specs/cql.html>:
    #
    # Double quotes enclosing a sequence of any characters except
    # double quote (unless preceded by backslash (\)). Backslash
    # escapes the character following it. The resultant value includes
    # all backslash characters except those releasing a double quote
    # (this allows other systems to interpret the backslash
    # character). The surrounding double quotes are not included.

    if value.end_with?('\\')
      raise DataError, "CQL query cannot support value ending with backslash"
    end

    escaped_value = value.gsub('"', '\"')

    cql_query = "rec.identifier=\"#{escaped_value}\""

    # Connect

    client = SRU::Client.new(use_test ? SRU_URL_TEST : SRU_URL_PRODUCTION)

    # Search (returns a SRU::SearchRetrieveResponse object)

    records = client.search_retrieve(cql_query,
                            :maximumRecords => 2,
                            :resultSetTTL => 0,
                            :recordSchema => RIFCS_SCHEMA)

    num_records = records.number_of_records
    if num_records.zero?
      # No match found
      return nil

    elsif 1 < num_records
      # Multiple records match the identifier: must be an error
      raise DataError, "multiple matches found: #{value}"

    else
      # Exactly one record match

      # Check that the requested identifier is found in the result as
      # an identifier.  This is to catch false matches, where the SRU
      # query returns a match when it should not (perhaps there was a
      # substring that matched).
      #
      # This problem does occur with the Trove SRU interface.
      # For example, searching for "mirage.cmm.uq.edu.au/user/1"
      # or "mirage.cmm.uq.edu.au/user" both returns a result.

      # Extract all the identifiers

      ids = nil
      records.each do |r|
        raise DataError, "multiple matches found: #{value}" if ! ids.nil?
        ids = records.rifcs_identifiers(r)
      end

      # Check that the requested ID (and optionally the type) is present

      if type
        # Type matters

        desired_ids = ids[type]

        if desired_ids
          if ! desired_ids.include?(value)
            return nil # identifier value not in result record
          end
        else
          return nil # identifier type of identifier not in result record
        end

      else
        # Type does not matter

        found = false
        ids.each_value do |v|
          if v.include?(value)
            found = true
          end
        end
        if ! found
          return nil # identifier (of any type) not in result record
        end
      end

      # Extract the RIF-CS registryObject key

      result = nil
      records.each do |r|
        if result
          raise DataError, "multiple records, but number of records is one"
        end
        result = records.rifcs_key(r)
      end
      return result

    end

  end

end

#EOF
