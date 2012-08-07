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
  end
end

#----------------------------------------------------------------

class TroveSRU

  # The NLA Party Infrastructure APIs are documented at:
  # https://wiki.nla.gov.au/display/ARDCPIP/Party+Infrastructure+APIs

  # The RIF-CS identifier type for a NLA Party Identifier.

  NLA_PARTY_ID_TYPE = 'AU-ANL:PEAU'

  # The URL for Trove's people and organisations SRU interface.

  SRU_INTERFACE = 'http://www.nla.gov.au/apps/srw/search/peopleaustralia'

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
  # *type* - the identifier type attribute
  #
  # *value* - the identifier value
  #
  # Returns the NLA Party Identifer as a string, or {nil} if not found
  #
  # Raises DataError if an internal error occurs

  def self.lookup_nla_id(type, value)

    client = SRU::Client.new(SRU_INTERFACE)

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
                            :recordSchema => RIFCS_SCHEMA)

    num_records = records.number_of_records
    if num_records.zero?
      return nil # none found

    elsif 1 < num_records
      raise DataError, "multiple matches found: #{value}"

    else

      ids = nil
      records.each do |r|
        raise DataError, "multiple matches found: #{value}" if ! ids.nil?
        ids = records.rifcs_identifiers(r)
      end

      # Check that the requested ID is present (this might not be a
      # correct check to make)

      desired_ids = ids[type]
      if desired_ids
        if ! desired_ids.find(value)
          raise DataError, "value not in result: #{value}"
        end
      else
          raise DataError, "type not in result: #{type}"
      end

      # Find the NLA Party Identifier

      nla_party_ids = ids[NLA_PARTY_ID_TYPE]
      if ! nla_party_ids
        raise DataError, "no NLA Party Identifier in result"
      elsif nla_party_ids.length == 0
        raise DataError, "no NLA Party Identifier in result"
      elsif 1 < nla_party_ids.length
        if nla_party_ids.index { |i| i != nla_party_ids[0] }
          raise DataError, "multiple different NLA Party Identifiers"
        end
      end

      return nla_party_ids[0]
    end

  end

end

#EOF
