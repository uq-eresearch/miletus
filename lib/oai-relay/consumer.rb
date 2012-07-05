require 'oai'

class Consumer

  # Take endpoint to use and collection to update
  def initialize(recordCollection, client = nil)
    is_client = [:get_record, :list_identifiers].all? do |method|
      client.respond_to?(method)
    end

    is_collection = [:get, :add, :remove, :format].all? do |method|
      recordCollection.respond_to?(method)
    end

    unless is_collection
      raise ArgumentError.new("Consumer requires a collection to update.")
    end
    @collection = recordCollection

    if is_client
      @client = client
    else
      @client = OAI::Client.new(recordCollection.endpoint)
    end
  end

  # Update collection with changed records
  def update
    @client.list_identifiers(:metadataPrefix => @collection.format)\
      .select { |header|
        existing = @collection.get(header.identifier)
        existing == nil or existing.datestamp < header.datestamp
      }.each { |header|
        record = @client.get_record(
            :identifier => header.identifier,
            :metadataPrefix => @collection.format).record
        @collection.add(record)
      }
  end

end