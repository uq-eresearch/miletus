require 'oai'

class Consumer
  
  module DataMixin
    def data
      @client.get_record(:metadata_format => @collection.format)
    end
  end
  
  # Take endpoint to use and collection to update
  def initialize(endpoint, recordCollection)
    is_client = [:get_record, :list_identifiers].all? do |method|
      endpoint.respond_to?(method)
    end
    
    is_collection = [:get, :add, :remove].all? do |method|
      recordCollection.respond_to?(method)
    end
    
    unless is_collection
      raise ArgumentError.new("Consumer requires a collection to update.")
    end
    @collection = recordCollection 
    
    if is_client
      @client = endpoint
    else
      begin
        @client = OAI::Client.new(endpoint)
      rescue URI::InvalidURIError
        raise ArgumentError.new("Consumer takes OAI::Client or endpoint URL.")
      end
    end
  end
  
  def update
    @client.list_identifiers(:metadata_format => @collection.format)\
      .select { |record|
        existing = @collection.get(record.identifier)
        existing == nil or existing.datestamp < record.datestamp
      }.each { |record|
        @collection.add(record.extend(DataMixin))
      }
  end
  
end