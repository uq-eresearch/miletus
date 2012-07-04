require 'oai-relay/consumer'
require 'yaml'

describe Consumer do

  # Convenience function for lambda
  def get_record_for_header(headers, identifier)
    headers.select { |header| header.identifier = identifier }\
      .map { |header| Struct.new(:header, :metadata).new(header, '<xml/>') }\
      .first
  end

  def get_record_response_for_header_lambda(filename)
    # Produce lambda
    lambda do |h|
      Struct.new(:record).new(
        get_record_for_header(
          get_fixture_objects(filename),
          h[:identifier]))
    end
  end

  def get_fixture_objects(filename)
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
    client.should_receive(:list_identifiers).with(:metadataPrefix => 'rif')\
      .and_return(get_fixture_objects('fixtures/list_identifiers_1.yaml'))
    # This should be called for all records
    client.should_receive(:get_record).exactly(8).times.and_return(
      &get_record_response_for_header_lambda('fixtures/list_identifiers_1.yaml')
    )

    recordCollection = double("RecordCollection")
    # Record collection should have its format checked
    recordCollection.should_receive(:format).at_least(:once).and_return('rif')
    # The collection should be checked for all records
    recordCollection.should_receive(:get).with(%r{^http://example.test/})\
                    .exactly(8).times.and_return(nil)
    # All records should be added
    recordCollection.should_receive(:add)\
                    .with(duck_type(:header, :metadata))\
                    .exactly(8).times
    # No records should be removed
    recordCollection.should_not_receive(:remove)

    consumer = Consumer.new(client, recordCollection)
    consumer.update()
  end

  it "updates records with different datetimes for an existing collection" do
    existing_records = get_fixture_objects('fixtures/list_identifiers_1.yaml')

    # OAI::Client and RecordCollection should be duck-typed
    client = double("OAI::Client")
    client.should_receive(:list_identifiers).with(:metadataPrefix => 'rif')\
      .and_return(get_fixture_objects('fixtures/list_identifiers_2.yaml'))
    # One new record => one call
    client.should_receive(:get_record).exactly(1).times.and_return(
      &get_record_response_for_header_lambda('fixtures/list_identifiers_2.yaml')
    )

    recordCollection = double("RecordCollection")
    # Record collection should have its format checked
    recordCollection.should_receive(:format).at_least(:once).and_return('rif')
    # The collection should be checked for all records
    recordCollection.should_receive(:get).with(%r{^http://example.test/})\
      .exactly(8).times.and_return { |q|
        existing_records.select { |r| q == r.identifier }.first
      }
    # All records should be added
    recordCollection.should_receive(:add)\
                    .with(duck_type(:header, :metadata))\
                    .exactly(1).times
    # No records should be removed
    recordCollection.should_not_receive(:remove)

    consumer = Consumer.new(client, recordCollection)
    consumer.update()
  end

end