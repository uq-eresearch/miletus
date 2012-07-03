require 'oai'

class Consumer
  
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
    @client.list_identifiers(@collection.format).select { |record|
      @collection.get(record) == nil
    }.each { |record|
      @collection.add(record)
    }
  end
  
end