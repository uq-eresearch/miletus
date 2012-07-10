require 'oai-relay/record_collection'
require 'support/active_record'

describe RecordCollection do

  subject {
    RecordCollection.new(
      :format => 'rif',
      :endpoint => 'http://example.test/oai'
    ).tap do |rc|
      rc.save()
      rc.readonly!
    end
  }

  it { should respond_to :add, :get, :remove, :format, :endpoint }

  it "returns nil if record is absent" do
    subject.get("http://example.test/1").should be nil
  end

  it "adds OAI::Record instances to a collection" do
    record = Struct.new(:header, :metadata).new(
        Struct.new(:identifier, :datestamp, :status).new(
          'http://example.test/1',
          DateTime.now),
        LibXML::XML::Node.new('xml'))
    subject.add(record)

    r = subject.get(record.header.identifier)
    r.header.identifier.should == record.header.identifier
    r.header.datestamp.iso8601.should == record.header.datestamp.iso8601
    r.metadata.should == record.metadata
  end

  it "updates existing OAI::Record instances in a collection" do
    records = (-10..-1).map do |i|
      Struct.new(:header, :metadata).new(
        Struct.new(:identifier, :datestamp, :status).new(
          'http://example.test/1',
          DateTime.now + i),
        LibXML::XML::Node.new('xml'))
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

  it "marks deleted OAI::Record instances as deleted in a collection" do
      record = Struct.new(:header, :metadata).new(
          Struct.new(:identifier, :datestamp, :status).new(
            'http://example.test/1',
            DateTime.now),
          LibXML::XML::Node.new('xml'))
      subject.add(record)

      # Check attributes are what they should be
      r = subject.get(record.header.identifier)
      r.header.identifier.should == record.header.identifier
      r.header.datestamp.iso8601.should == record.header.datestamp.iso8601
      r.header.deleted?.should be_false

      subject.remove(record.header.identifier)

      # Check attributes are what they should be
      r = subject.get(record.header.identifier)
      r.header.identifier.should == record.header.identifier
      r.header.datestamp.iso8601.should == record.header.datestamp.iso8601
      r.header.deleted?.should be_true
    end

  it "silently ignores new deleted OAI::Record instances in a collection" do
      header = Struct.new(:identifier, :datestamp).new(
            'http://example.test/1',
            DateTime.now)

      subject.remove(header.identifier, header.datestamp)

      # Check attributes are what they should be
      r = subject.get(header.identifier)
      r.should be_nil
    end

end