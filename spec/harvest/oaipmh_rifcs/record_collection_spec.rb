require 'spec_helper'
require File.join(File.dirname(__FILE__), 'fixtures', 'oai')

describe Miletus::Harvest::OAIPMH::RIFCS::RecordCollection do

  subject {
    Miletus::Harvest::OAIPMH::RIFCS::RecordCollection.new(
      :endpoint => 'http://example.test/oai'
    ).tap do |rc|
      rc.save()
      rc.readonly!
    end
  }

  it { should respond_to(:format, :endpoint, :set) }
  it { should respond_to(:add, :get, :remove) }
  it { should respond_to(:restrict_to) }

  describe "#set" do
    it "returns nil if set is unspecified" do
      rc = Miletus::Harvest::OAIPMH::RIFCS::RecordCollection.new(
        :endpoint => 'http://example.test/oai'
      )
      rc.set.should be_nil
    end
    it "returns set if present" do
      rc = Miletus::Harvest::OAIPMH::RIFCS::RecordCollection.new(
        :endpoint => 'http://example.test/oai',
        :set => 'foobar'
      )
      rc.set.should == 'foobar'
    end
    it "returns nil if set is blank" do
      rc = Miletus::Harvest::OAIPMH::RIFCS::RecordCollection.new(
        :endpoint => 'http://example.test/oai',
        :set => ''
      )
      rc.set.should be_nil
    end
  end

  it "returns nil if record is absent" do
    subject.get("http://example.test/1").should be(nil)
  end

  it "adds OAI::Record instances to a collection" do
    record = FactoryGirl.build(:oai_record)
    subject.add(record)

    r = subject.get(record.header.identifier)
    r.header.identifier.should be == record.header.identifier
    r.header.datestamp.to_i.should be == record.header.datestamp.to_i
    r.metadata.should be == record.metadata
  end

  it "updates existing OAI::Record instances in a collection" do
    records = 10.downto(1).map do |i|
      FactoryGirl.build :oai_record,
        :header => FactoryGirl.build(:oai_header,
          :datestamp => i.hours.ago)
    end
    records.each do |record|
      subject.add(record)
      # Check attributes are what they should be
      r = subject.get(record.header.identifier)
      r.header.identifier.should be == record.header.identifier
      r.header.datestamp.to_i.should be == record.header.datestamp.to_i
      r.metadata.should be == record.metadata
    end
  end

  it "marks deleted OAI::Record instances as deleted in a collection" do
    record = FactoryGirl.build(:oai_record)
    subject.add(record)

    # Check attributes are what they should be
    r = subject.get(record.header.identifier)
    r.header.identifier.should be == record.header.identifier
    r.header.datestamp.to_i.should be == record.header.datestamp.to_i
    r.header.deleted?.should be_false

    subject.remove(record.header.identifier)

    # Check attributes are what they should be
    r = subject.get(record.header.identifier)
    r.header.identifier.should be == record.header.identifier
    r.header.datestamp.to_i.should be == record.header.datestamp.to_i
    r.header.deleted?.should be_true
  end

  it "silently ignores new deleted OAI::Record instances in a collection" do
    header = FactoryGirl.build(:oai_header)

    subject.remove(header.identifier, header.datestamp)

    # Check attributes are what they should be
    r = subject.get(header.identifier)
    r.should be_nil
  end

  it "knows which records it has seen, and can delete unseen records" do
    record1 = FactoryGirl.build(:oai_record)
    subject.add(record1)

    r = subject.get(record1.header.identifier)
    r.header.identifier.should be == record1.header.identifier
    r.header.datestamp.to_i.should be == record1.header.datestamp.to_i
    r.metadata.should be == record1.metadata

    record2 = FactoryGirl.build(:oai_record)
    subject.restrict_to do
      subject.add(record2)
    end

    r = subject.get(record2.header.identifier)
    r.should_not be_nil
    r.header.identifier.should be == record2.header.identifier
    r.header.datestamp.to_i.should be == record2.header.datestamp.to_i
    r.metadata.should be == record2.metadata

    # Original (unseen) record should not be there
    subject.get(record1.header.identifier).should be_nil
  end

end