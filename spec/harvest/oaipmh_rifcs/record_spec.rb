require 'spec_helper'
require File.join(File.dirname(__FILE__), 'fixtures', 'oai')

describe Miletus::Harvest::OAIPMH::RIFCS::Record do

  def get_xml_fixture(type, number = 1)
    fixture_file = File.join(File.dirname(__FILE__),
        '..', '..', 'fixtures',"rifcs-#{type}-#{number}.xml")
    IO.read(fixture_file)
  end

  it { should respond_to(:to_rif) }

  it "is creatable with no arguments" do
    Miletus::Harvest::OAIPMH::RIFCS::Record.new()
  end

  it "is creatable using an OAI::Record" do
    oaiRecord = FactoryGirl.build(:oai_record)
    oaiRecord.header.should respond_to('deleted?'.to_sym)
    record = Miletus::Harvest::OAIPMH::RIFCS::Record.from_oai(oaiRecord)
    record.identifier.should be == oaiRecord.header.identifier
    record.datestamp.should be == oaiRecord.header.datestamp
    record.metadata.should == oaiRecord.metadata.to_s
  end

  it "converts to an OAI::Record" do
    record = Miletus::Harvest::OAIPMH::RIFCS::Record.new(
      :identifier => 'http://example.test/1',
      :datestamp => DateTime.now,
      :metadata => '<metadata/>')
    oaiRecord = record.to_oai
    oaiRecord.header.identifier.should be == record.identifier
    oaiRecord.header.datestamp.should be == record.datestamp
    oaiRecord.metadata.to_s.should == record.metadata
  end

  it "saves timezones as UTC" do
    selected_time = Time.now.round # DB is only precise to seconds
    record = Miletus::Harvest::OAIPMH::RIFCS::Record.create(
      :identifier => 'http://example.test/1',
      :datestamp => selected_time,
      :metadata => '<metadata/>')
    record.datestamp.zone.should be == 'UTC'
    record.datestamp.should be == selected_time
  end

  it "produces a valid RIF-CS record" do
    fixture_xml = Nokogiri::XML(get_xml_fixture('collection')).tap do |doc|
      old_root = doc.root
      doc.root = Nokogiri::XML::Node.new('metadata', doc)
      doc.root << old_root
    end.to_s
    record = Miletus::Harvest::OAIPMH::RIFCS::Record.new(
      :identifier => 'http://example.test/1',
      :datestamp => DateTime.now,
      :metadata => fixture_xml)
    rifcs_doc = Nokogiri::XML(record.to_rif)
    ns_by_prefix('rif').schema.validate(rifcs_doc).should be == []
  end

  it "produces a valid RIF-CS record when undefined namespace prefixes exist" do
    fixture_xml = Nokogiri::XML(get_xml_fixture('collection')).tap do |doc|
      old_root = doc.root
      doc.root = Nokogiri::XML::Node.new('metadata', doc)
      doc.root << old_root
    end.to_s.gsub(
      /(registryObjects .*)>$/,
      "\\1 xsi:schemaLocation=\""+
      "http://ands.org.au/standards/rif-cs/registryObjects "+
      "http://services.ands.org.au/documentation/"+
      "rifcs/schema/registryObjects.xsd\">")
    expect do
      Nokogiri::XML::Reader(fixture_xml).each do |n|
        # Do nothing
      end
    end.to raise_error
    record = Miletus::Harvest::OAIPMH::RIFCS::Record.new(
      :identifier => 'http://example.test/1',
      :datestamp => DateTime.now,
      :metadata => fixture_xml)
    expect do
      Nokogiri::XML::Reader(record.to_rif).each do |n|
        # Do nothing
      end
    end.to_not raise_error
    rifcs_doc = Nokogiri::XML(record.to_rif)
    ns_by_prefix('rif').schema.validate(rifcs_doc).should be == []
  end

end
