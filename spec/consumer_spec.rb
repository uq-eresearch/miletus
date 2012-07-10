require 'oai-relay/consumer'
require 'yaml'

describe Consumer do

  it "takes a RecordCollection and optional OAI-PMH client for init" do
    # Need an argument
    lambda { Consumer.new() }.should raise_error(ArgumentError)

    # Not just any arguments
    lambda {
      Consumer.new(Object.new())
    }.should raise_error(ArgumentError)
    lambda {
      Consumer.new(Object.new(), Object.new())
    }.should raise_error(ArgumentError)

    # OAI::Client and RecordCollection should be duck-typed
    client = double("OAI::Client")
    client.stub(:get_record)
    client.stub(:list_identifiers)
    recordCollection = double("RecordCollection")
    recordCollection.should_receive(:endpoint)\
                    .and_return("http://example.test/oai")
    recordCollection.stub(:format)
    recordCollection.stub(:get)
    recordCollection.stub(:add)
    recordCollection.stub(:remove)

    # Explicit client should be fine
    Consumer.new(recordCollection, client)
    # Implicit client should be fine
    Consumer.new(recordCollection)
  end

  it "adds all records for an empty collection" do
    # OAI::Client and RecordCollection should be duck-typed
    client = double("OAI::Client")
    client.should_receive(:list_identifiers).with(:metadataPrefix => 'rif')\
      .and_return(get_fixture_objects('fixtures/list_identifiers_1.yaml'))
    # This should be called for all records
    client.should_receive(:get_record).exactly(8).times.and_return(
      &get_record_by_identifier_lambda('fixtures/list_identifiers_1.yaml')
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

    consumer = Consumer.new(recordCollection, client)
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
      &get_record_by_identifier_lambda('fixtures/list_identifiers_2.yaml')
    )

    recordCollection = double("RecordCollection")
    # Record collection should have its format checked
    recordCollection.should_receive(:format).at_least(:once).and_return('rif')
    # The collection should be checked for all records
    recordCollection.should_receive(:get).with(%r{^http://example.test/})\
      .exactly(8).times.and_return { |q|
        get_record_by_identifier(existing_records, q)
      }
    # All records should be added
    recordCollection.should_receive(:add)\
                    .with(duck_type(:header, :metadata))\
                    .exactly(1).times
    # No records should be removed
    recordCollection.should_not_receive(:remove)

    consumer = Consumer.new(recordCollection, client)
    consumer.update()
  end

  it "removes deleted records for an existing collection" do
    existing_records = get_fixture_objects('fixtures/list_identifiers_2.yaml')

    # OAI::Client and RecordCollection should be duck-typed
    client = double("OAI::Client")
    client.should_receive(:list_identifiers).with(:metadataPrefix => 'rif')\
      .and_return(get_fixture_objects('fixtures/list_identifiers_3.yaml'))
    # One new record => one call
    client.should_receive(:get_record).exactly(3).times.and_return(
      &get_record_by_identifier_lambda('fixtures/list_identifiers_3.yaml')
    )

    recordCollection = double("RecordCollection")
    # Record collection should have its format checked
    recordCollection.should_receive(:format).at_least(:once).and_return('rif')
    # The collection should be checked for all records
    recordCollection.should_receive(:get).with(%r{^http://example.test/})\
      .exactly(9).times.and_return { |q|
        get_record_by_identifier(existing_records, q)
      }
    # 3 of 8 records should be added
    recordCollection.should_receive(:add)\
                    .with(duck_type(:header, :metadata))\
                    .exactly(3).times
    # No records should be removed
    recordCollection.should_receive(:remove)\
                    .with(kind_of(String), kind_of(Time))\
                    .exactly(6).times

    consumer = Consumer.new(recordCollection, client)
    consumer.update()
  end

  def header_to_record(header)
    Struct.new(:header, :metadata).new(header, XML::Node.new('xml'))
  end

  def get_header_by_identifier(headers, identifier)
    headers.select { |header| header.identifier = identifier }.first
  end

  # Convenience function for lambda
  def get_record_by_identifier(*args)
    header_to_record(get_header_by_identifier(*args))
  end

  def get_record_by_identifier_lambda(filename)
    # Produce lambda
    lambda do |h|
      Struct.new(:record).new(
        get_record_by_identifier(
          get_fixture_objects(filename),
          h[:identifier]))
    end
  end

  def get_fixture_objects(filename)
    File.open(File.join(File.dirname(__FILE__), filename)) do |f|
      YAML::load(f.read())
    end
  end

  # Loaded as a fixture
  Struct::new('OaiHeaderStruct', :identifier, :datestamp, :status) do
    def deleted?
      status == 'deleted'
    end
  end

end