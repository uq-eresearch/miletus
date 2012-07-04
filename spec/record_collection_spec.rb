require 'oai-relay/record_collection'
require 'support/active_record'

describe RecordCollection do

  it { should respond_to :add, :get, :remove }

  it "should add OAI::Record instances to a collection" do
    subject.format = 'rif'
    subject.endpoint = 'http://example.test/oai'
    subject.save()

    record = Struct.new(:header, :metadata).new(
        Struct.new(:identifier, :datestamp).new(
          'http://example.test/1',
          DateTime.now),
        '<xml/>')
    subject.add(record)

    r = subject.get(record.header.identifier)
    r.identifier.should == record.header.identifier
    r.datestamp.iso8601.should == record.header.datestamp.iso8601
    r.metadata.should == record.metadata
  end

  it "should update existing OAI::Record instances in a collection" do
    subject.format = 'rif'
    subject.endpoint = 'http://example.test/oai'
    subject.save()

    records = (-10..-1).map do |i|
      Struct.new(:header, :metadata).new(
        Struct.new(:identifier, :datestamp).new(
          'http://example.test/1',
          DateTime.now + i),
        '<xml/>')
    end

    record_ids = records.map do |record|
      subject.add(record)
      # Check attributes are what they should be
      r = subject.get(record.header.identifier)
      r.identifier.should == record.header.identifier
      r.datestamp.iso8601.should == record.header.datestamp.iso8601
      r.metadata.should == record.metadata
      # Return ID for checking
      r.id
    end

    # Whatever ID is allocated, it should be the same one in every case
    record_ids.to_set.size.should == 1
  end

end