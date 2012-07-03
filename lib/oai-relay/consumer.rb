require 'oai'

class Consumer
  
  def initialize(endpoint)
    is_client = [:identify, :get_record, :list_identifiers].all? do |method|
      endpoint.respond_to?(method)
    end
    
    if is_client
      @client = endpoint
    else
      begin
        @client = OAI::Client.new(endpoint)
      rescue URI::InvalidURIError
        raise ArgumentError.new("Reader takes OAI::Client or endpoint URL")
      end
    end
  end
  
  
  
end