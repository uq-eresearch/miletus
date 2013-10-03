require 'spec_helper'
require 'yaml'
require File.join(File.dirname(__FILE__), 'fixtures', 'oai')

describe Miletus::Harvest::OAIPMH::RIFCS::Consumer do

  subjectClass = Miletus::Harvest::OAIPMH::RIFCS::Consumer

  it "takes a RecordCollection and optional OAI-PMH client for init" do
    # Need an argument
    lambda { subjectClass.new() }.should raise_error(ArgumentError)

    # Not just any arguments
    lambda {
      subjectClass.new(Object.new())
    }.should raise_error(ArgumentError)
    lambda {
      subjectClass.new(Object.new(), Object.new())
    }.should raise_error(ArgumentError)

    # OAI::Client and RecordCollection should be duck-typed
    client = double("OAI::Client")
    client.stub(:get_record)
    client.stub(:list_identifiers)
    recordCollection = double("RecordCollection")
    recordCollection.stub(:endpoint)
    recordCollection.stub(:format)
    recordCollection.stub(:get)
    recordCollection.stub(:add)
    recordCollection.stub(:remove)

    # Explicit client should be fine
    subjectClass.new(recordCollection, client)
    # Implicit client should be fine
    subjectClass.new(recordCollection)
  end

  it "should be a valid delayed job" do
    recordCollection = double("RecordCollection")
    recordCollection.stub(:endpoint)
    recordCollection.stub(:format)
    recordCollection.stub(:get)
    recordCollection.stub(:add)
    recordCollection.stub(:remove)
    # All delayed jobs must respond to :perform
    subjectClass.new(recordCollection).should respond_to(:perform)
  end

  it "adds all records for an empty collection" do
    # OAI::Client and RecordCollection should be duck-typed
    client = double("OAI::Client")
    client.should_receive(:list_identifiers).with(:metadataPrefix => 'rif')\
      .and_return(Struct.new(:full).new(
        get_fixture_objects(list_identifiers_1)))
    # This should be called for all records
    client.should_receive(:get_record).exactly(8).times.and_return(
      &get_record_by_identifier_lambda(list_identifiers_1)
    )

    recordCollection = double("RecordCollection")
    recordCollection.should_receive(:restrict_to).once.and_yield
    # Record collection should have its format checked
    recordCollection.should_receive(:format).at_least(:once).and_return('rif')
    # Record collection should have its set used
    recordCollection.should_receive(:set).at_least(:once).and_return(nil)
    # The collection should be checked for all records
    recordCollection.should_receive(:get).with(%r{^http://example.test/})\
                    .exactly(8).times.and_return(nil)
    # All records should be added
    recordCollection.should_receive(:add)\
                    .with(duck_type(:header, :metadata))\
                    .exactly(8).times
    # No records should be removed
    recordCollection.should_not_receive(:remove)

    consumer = subjectClass.new(recordCollection, client)
    consumer.update()
  end

  it "updates records with different datetimes for an existing collection" do
    existing_records = get_fixture_objects(list_identifiers_1)

    # OAI::Client and RecordCollection should be duck-typed
    client = double("OAI::Client")
    client.should_receive(:list_identifiers).with(:metadataPrefix => 'rif')\
      .and_return(Struct.new(:full).new(
        get_fixture_objects(list_identifiers_2)))
    # One new record => one call
    client.should_receive(:get_record).exactly(1).times.and_return(
      &get_record_by_identifier_lambda(list_identifiers_2)
    )

    recordCollection = double("RecordCollection")
    recordCollection.should_receive(:restrict_to).once.and_yield
    # Record collection should have its format checked
    recordCollection.should_receive(:format).at_least(:once).and_return('rif')
    # Record collection should have its set used
    recordCollection.should_receive(:set).at_least(:once).and_return(nil)
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

    consumer = subjectClass.new(recordCollection, client)
    consumer.update()
  end

  it "removes deleted records for an existing collection" do
    existing_records = get_fixture_objects(list_identifiers_2)

    # OAI::Client and RecordCollection should be duck-typed
    client = double("OAI::Client")
    client.should_receive(:list_identifiers).with(:metadataPrefix => 'rif')\
      .and_return(Struct.new(:full).new(
        get_fixture_objects(list_identifiers_3)))
    # One new record => one call
    client.should_receive(:get_record).exactly(3).times.and_return(
      &get_record_by_identifier_lambda(list_identifiers_3)
    )

    recordCollection = double("RecordCollection")
    recordCollection.should_receive(:restrict_to).once.and_yield
    # Record collection should have its format checked
    recordCollection.should_receive(:format).at_least(:once).and_return('rif')
    # Record collection should have its set used
    recordCollection.should_receive(:set).at_least(:once).and_return(nil)
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

    consumer = subjectClass.new(recordCollection, client)
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

  def get_record_by_identifier_lambda(objects)
    # Produce lambda
    lambda do |h|
      Struct.new(:record).new(
        get_record_by_identifier(
          get_fixture_objects(objects),
          h[:identifier]))
    end
  end

  def get_fixture_objects(objects)
    response = objects
    response.should_receive(:resumption_token)\
            .any_number_of_times.and_return(nil)
    response
  end

  let(:identifier_sequence) do
    Enumerator.new do |y|
      i = 1
      loop do
        y << "http://example.test/#{i}"
        i += 1
      end
    end
  end

  let(:list_identifiers_1) do
    identifier_sequence.take(8).map do |identifier|
      FactoryGirl.build :oai_header,
        identifier: identifier,
        datestamp: Time.parse('2012-07-03T09:17:47Z')
    end
  end

  let(:list_identifiers_2) do
    l = list_identifiers_1
    l[2].datestamp = Time.parse('2012-07-03T10:17:47Z')
    l
  end

  let(:list_identifiers_3) do
    identifier_sequence.take(9).each_with_index.map do |identifier, i|
      FactoryGirl.build :oai_header,
        identifier: identifier,
        datestamp: Time.parse('2012-07-03T12:17:47Z'),
        deleted: !i.succ.between?(6,8) # Leave last 3 in original list
    end
  end

end