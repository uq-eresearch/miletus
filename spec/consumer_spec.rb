require 'oai-relay/consumer'
require 'yaml'

describe Consumer do

  def get_fixture_records(filename)
    File.open(File.join(File.dirname(__FILE__), filename)) do |f| 
      YAML::load(f.read()).map do |h|
        # Convert hashes to structs which resemble OAI::Header
        k,v = h.to_a.transpose
        Struct.new(*k).new(*v)
      end
    end
  end
    
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
    client.should_receive(:list_identifiers).with(:metadata_format => 'rif')\
      .and_return(get_fixture_records('fixtures/list_identifiers_1.yaml'))
    # This should be lazily called
    client.should_not_receive(:get_record)
    
    recordCollection = double("RecordCollection")
    # Record collection should have its format checked
    recordCollection.should_receive(:format).at_least(:once).and_return('rif')
    # The collection should be checked for all records
    recordCollection.should_receive(:get).with(%r{^http://example.test/})\
                    .exactly(8).times.and_return(nil)
    # All records should be added
    recordCollection.should_receive(:add).with(duck_type(:identifier, :data))\
                    .exactly(8).times
    # No records should be removed
    recordCollection.should_not_receive(:remove)
    
    consumer = Consumer.new(client, recordCollection) 
    consumer.update()
  end
  
  it "updates records with different datetimes for an existing collection" do
    existing_records = get_fixture_records('fixtures/list_identifiers_1.yaml')
    
    # OAI::Client and RecordCollection should be duck-typed
    client = double("OAI::Client")
    client.should_receive(:list_identifiers).with(:metadata_format => 'rif')\
      .and_return(get_fixture_records('fixtures/list_identifiers_2.yaml'))
    # This should be lazily called
    client.should_not_receive(:get_record)
    
    recordCollection = double("RecordCollection")
    # Record collection should have its format checked
    recordCollection.should_receive(:format).at_least(:once).and_return('rif')
    # The collection should be checked for all records
    recordCollection.should_receive(:get).with(%r{^http://example.test/})\
      .exactly(8).times.and_return { |q|
        existing_records.select { |r| q == r.identifier }.first
      }
    # All records should be added
    recordCollection.should_receive(:add).with(duck_type(:identifier, :data))\
                    .exactly(1).times
    # No records should be removed
    recordCollection.should_not_receive(:remove)
    
    consumer = Consumer.new(client, recordCollection) 
    consumer.update()
  end
  
end