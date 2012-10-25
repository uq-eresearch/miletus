require 'spec_helper'

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
    oaiRecord = Struct.new(:header, :metadata).new(
        Struct.new(:identifier, :datestamp, :status) do
          def deleted?
            self.status == 'deleted'
          end
        end.new(
          'http://example.test/1',
          DateTime.now),
        LibXML::XML::Node.new('metadata'))
    oaiRecord.header.should respond_to('deleted?'.to_sym)
    record = Miletus::Harvest::OAIPMH::RIFCS::Record.from_oai(oaiRecord)
    record.identifier.should == oaiRecord.header.identifier
    record.datestamp.should == oaiRecord.header.datestamp
    record.metadata.should == oaiRecord.metadata.to_s
  end

  it "converts to an OAI::Record" do
    record = Miletus::Harvest::OAIPMH::RIFCS::Record.new(
      :identifier => 'http://example.test/1',
      :datestamp => DateTime.now,
      :metadata => '<metadata/>')
    oaiRecord = record.to_oai
    oaiRecord.header.identifier.should == record.identifier
    oaiRecord.header.datestamp.should == record.datestamp
    oaiRecord.metadata.to_s.should == record.metadata
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
    ns_by_prefix('rif').schema.valid?(rifcs_doc).should be_true
  end

end
