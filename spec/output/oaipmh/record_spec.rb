require 'spec_helper'
require 'time'
require 'miletus/output/oaipmh/record'

describe Miletus::Output::OAIPMH::Record do

  NS_DECL = %w{ dc:http://purl.org/dc/elements/1.1/
                oai_dc:http://www.openarchives.org/OAI/2.0/oai_dc/
                rif:http://ands.org.au/standards/rif-cs/registryObjects }

  context "OAI Dublin Core" do
    it { should respond_to(:to_oai_dc) }

    it "should return nil if record cannot generate valid Dublin Core" do
      subject.to_oai_dc.should be(nil)
    end

    context "should return valid OAI Dublin Core if provided with" do
      %w{collection party activity service}.each do |type|
        example "a RIF-CS #{type}" do
          fixture_file = File.join(File.dirname(__FILE__),
            '..', '..', 'fixtures',"rifcs-#{type}-1.xml")
          subject.metadata = File.open(fixture_file) { |f| f.read() }
          subject.to_oai_dc.should_not be(nil)
          # Validate the XML
          dc_doc = XML::Document.string(subject.to_oai_dc)
          dc_schema = subject.class.get_schema('oai_dc')
          dc_doc.validate_schema(dc_schema).should be(true)
        end
      end
    end

    it "should handle alternate RIF-CS names" do
      fixture_file = File.join(File.dirname(__FILE__),
        '..', '..', 'fixtures',"rifcs-party-1.xml")
      subject.metadata = File.open(fixture_file) { |f| f.read() }
      subject.to_oai_dc.should_not be(nil)
      # Validate the XML
      dc_doc = XML::Document.string(subject.to_oai_dc)
      dc_doc.find("//dc:title", NS_DECL).map {|n| n.content }.should \
        == ["Dettrick, Timothy John", "Dettrick, Tim"]
    end

  end

  context "RIF-CS" do
    it { should respond_to(:to_rif) }

    it "should return nil if record cannot generate valid RIF-CS" do
      subject.to_rif.should be(nil)
      subject.metadata = "<xml/>"
      subject.to_rif.should be(nil)
    end

    context "should return valid RIF-CS if provided with" do
      %w{collection party activity service}.each do |type|
        example "a RIF-CS #{type}" do
          fixture_file = File.join(File.dirname(__FILE__),
            '..', '..', 'fixtures',"rifcs-#{type}-1.xml")
          subject.metadata = File.open(fixture_file) { |f| f.read() }
          subject.to_rif.should_not be(nil)
          # Validate the XML
          rifcs_doc = XML::Document.string(subject.to_rif)
          rifcs_schema = subject.class.get_schema('rif')
          rifcs_doc.validate_schema(rifcs_schema).should be(true)
        end
      end
    end

    it "should update dateModified when saved" do
      fixture_file = File.join(File.dirname(__FILE__),
        '..', '..', 'fixtures',"rifcs-party-1.xml")
      subject.metadata = File.open(fixture_file) { |f| f.read() }
      subject.to_oai_dc.should_not be(nil)
      subject.save!
      # Validate the XML
      rifcs_doc = XML::Document.string(subject.to_rif)
      rifcs_doc.find_first("//@dateModified", NS_DECL).value.should \
        == subject.updated_at.iso8601
    end

  end

end
