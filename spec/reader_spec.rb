require 'oai-relay/reader'

describe Reader do
  it "takes an OAI-PMH client for initialization" do
    # Need an argument
    lambda { Reader.new() }.should raise_error(ArgumentError)
    
    # Not just any argument
    lambda { Reader.new(Object.new()) }.should raise_error(ArgumentError)
    

    # Object should resemble an OAI::Client
    client = double("OAI::Client")
    client.stub(:identify)
    client.stub(:get_record)
    client.stub(:list_identifiers)
    Reader.new(client)
    
    # A string will also do
    Reader.new("http://example.test")
  end
  
end