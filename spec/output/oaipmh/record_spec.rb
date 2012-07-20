require 'spec_helper'
require 'miletus/output/oaipmh/record'

describe Miletus::Output::OAIPMH::Record do

  describe "OAI Dublin Core" do
    it { should respond_to(:to_oai_dc) }

    it "should return nil if record cannot generate valid Dublin Core" do
      subject.to_oai_dc.should be(nil)
    end

    it "should return OAI Dublin Core if provided valid RIF-CS" do
      fixture_file = File.join(File.dirname(__FILE__),
        '..', '..', 'fixtures','rifcs-party-1.xml')
      subject.metadata = File.open(fixture_file) { |f| f.read() }
      subject.to_oai_dc.should_not be(nil)
      # Validate the XML
      rifcs_doc = XML::Document.string(subject.to_oai_dc)
      rifcs_schema = subject.class.get_schema('oai_dc')
      rifcs_doc.validate_schema(rifcs_schema).should be(true)
    end

  end

  describe "RIF-CS" do
    it { should respond_to(:to_rif) }

    it "should return nil if record cannot generate valid RIF-CS" do
      subject.to_rif.should be(nil)
      subject.metadata = "<xml/>"
      subject.to_rif.should be(nil)
    end

    it "should return RIF-CS if provided valid RIF-CS" do
      fixture_file = File.join(File.dirname(__FILE__),
        '..', '..', 'fixtures','rifcs-party-1.xml')
      subject.metadata = File.open(fixture_file) { |f| f.read() }
      subject.to_rif.should_not be(nil)
      # Validate the XML
      rifcs_doc = XML::Document.string(subject.to_rif)
      rifcs_schema = subject.class.get_schema('rif')
      rifcs_doc.validate_schema(rifcs_schema).should be(true)
    end

  end

end
