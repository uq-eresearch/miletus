require 'oai-relay/consumer'
require 'yaml'

describe Consumer do
  
  it "takes an OAI-PMH client and RecordCollection for initialization" do
    # Need an argument
    lambda { Consumer.new() }.should raise_error(ArgumentError)
    
    # Not just any arguments
    lambda { 
      Consumer.new(Object.new(), Object.new()) 
    }.should raise_error(ArgumentError)
    
    # OAI::Client and RecordCollection should be duck-typed
    client = double("OAI::Client")
    client.stub(:get_record)
    client.stub(:list_identifiers)
    recordCollection = double("RecordCollection")
    recordCollection.stub(:format)
    recordCollection.stub(:get)
    recordCollection.stub(:add)
    recordCollection.stub(:remove)
    
    Consumer.new(client, recordCollection) 

    # Check both arguments
    lambda { 
      Consumer.new(client, Object.new()) 
    }.should raise_error(ArgumentError)
    lambda { 
      Consumer.new(Object.new(), recordCollection) 
    }.should raise_error(ArgumentError)
    
    # A string will also do
    Consumer.new("http://example.test/oai", recordCollection)
  end
  
  it "adds all records for an empty collection" do
    # OAI::Client and RecordCollection should be duck-typed
    client = double("OAI::Client")
    client.should_receive(:list_identifiers).and_return(
      # Read response from fixture
      File.open(File.join(File.dirname(__FILE__), 
        'fixtures/list_identifiers_1.yaml')) do |f| 
        YAML::load(f.read())
      end
    )
    # This should be lazily called
    client.should_not_receive(:get_record)
    
    recordCollection = double("RecordCollection")
    # Record collection should have its format checked
    recordCollection.should_receive(:format).at_least(:once).and_return('rif')
    # The collection should be checked for all records
    recordCollection.should_receive(:get).exactly(8).times.and_return(nil)
    # All records should be added
    recordCollection.should_receive(:add).exactly(8).times
    # No records should be removed
    recordCollection.should_not_receive(:remove)
    
    consumer = Consumer.new(client, recordCollection) 
    consumer.update()
  end
  
  
end