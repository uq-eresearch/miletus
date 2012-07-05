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
    r.header.identifier.should == record.header.identifier
    r.header.datestamp.iso8601.should == record.header.datestamp.iso8601
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

    records.each do |record|
      subject.add(record)
      # Check attributes are what they should be
      r = subject.get(record.header.identifier)
      r.header.identifier.should == record.header.identifier
      r.header.datestamp.iso8601.should == record.header.datestamp.iso8601
      r.metadata.should == record.metadata
    end

  end

end