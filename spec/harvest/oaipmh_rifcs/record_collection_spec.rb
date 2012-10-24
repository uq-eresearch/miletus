require 'spec_helper'

describe Miletus::Harvest::OAIPMH::RIFCS::RecordCollection do

  subject {
    Miletus::Harvest::OAIPMH::RIFCS::RecordCollection.new(
      :endpoint => 'http://example.test/oai'
    ).tap do |rc|
      rc.save()
      rc.readonly!
    end
  }

  it { should respond_to(:format, :endpoint) }
  it { should respond_to(:add, :get, :remove) }
  it { should respond_to(:restrict_to) }

  it "returns nil if record is absent" do
    subject.get("http://example.test/1").should be(nil)
  end

  it "adds OAI::Record instances to a collection" do
    record = Struct.new(:header, :metadata).new(
        Struct.new(:identifier, :datestamp, :status).new(
          'http://example.test/1',
          DateTime.now),
        LibXML::XML::Node.new('metadata'))
    subject.add(record)

    r = subject.get(record.header.identifier)
    r.header.identifier.should == record.header.identifier
    r.header.datestamp.to_i.should == record.header.datestamp.to_i
    r.metadata.should == record.metadata
  end

  it "updates existing OAI::Record instances in a collection" do
    records = (-10..-1).map do |i|
      Struct.new(:header, :metadata).new(
        Struct.new(:identifier, :datestamp, :status).new(
          'http://example.test/1',
          DateTime.now + i),
        LibXML::XML::Node.new('metadata'))
    end

    records.each do |record|
      subject.add(record)
      # Check attributes are what they should be
      r = subject.get(record.header.identifier)
      r.header.identifier.should == record.header.identifier
      r.header.datestamp.to_i.should == record.header.datestamp.to_i
      r.metadata.should == record.metadata
    end
  end

  it "marks deleted OAI::Record instances as deleted in a collection" do
    record = Struct.new(:header, :metadata).new(
        Struct.new(:identifier, :datestamp, :status).new(
          'http://example.test/1',
          DateTime.now),
        LibXML::XML::Node.new('metadata'))
    subject.add(record)

    # Check attributes are what they should be
    r = subject.get(record.header.identifier)
    r.header.identifier.should == record.header.identifier
    r.header.datestamp.to_i.should == record.header.datestamp.to_i
    r.header.deleted?.should be_false

    subject.remove(record.header.identifier)

    # Check attributes are what they should be
    r = subject.get(record.header.identifier)
    r.header.identifier.should == record.header.identifier
    r.header.datestamp.to_i.should == record.header.datestamp.to_i
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

  it "knows which records it has seen, and can delete unseen records" do
    record1 = Struct.new(:header, :metadata).new(
        Struct.new(:identifier, :datestamp, :status).new(
          'http://example.test/1',
          DateTime.now),
        LibXML::XML::Node.new('metadata'))
    subject.add(record1)

    r = subject.get(record1.header.identifier)
    r.header.identifier.should == record1.header.identifier
    r.header.datestamp.to_i.should == record1.header.datestamp.to_i
    r.metadata.should == record1.metadata

    record2 = Struct.new(:header, :metadata).new(
      Struct.new(:identifier, :datestamp, :status).new(
        'http://example.test/2',
        DateTime.now),
      LibXML::XML::Node.new('metadata'))
    subject.restrict_to do
      subject.add(record2)
    end

    r = subject.get(record2.header.identifier)
    r.should_not be_nil
    r.header.identifier.should == record2.header.identifier
    r.header.datestamp.to_i.should == record2.header.datestamp.to_i
    r.metadata.should == record2.metadata

    # Original (unseen) record should not be there
    subject.get(record1.header.identifier).should be_nil
  end

end