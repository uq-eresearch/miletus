require 'oai-relay/consumer'

describe Consumer do
  
  it "takes an OAI-PMH client for initialization" do
    # Need an argument
    lambda { Consumer.new() }.should raise_error(ArgumentError)
    
    # Not just any argument
    lambda { Consumer.new(Object.new()) }.should raise_error(ArgumentError)
    
    # Object should resemble an OAI::Client
    client = double("OAI::Client")
    client.stub(:identify)
    client.stub(:get_record)
    client.stub(:list_identifiers)
    Consumer.new(client)
    
    # A string will also do
    Consumer.new("http://example.test/oai")
  end
  
  
  
  
end