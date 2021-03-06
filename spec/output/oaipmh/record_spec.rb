require 'spec_helper'
require 'time'

describe Miletus::Output::OAIPMH::Record do

  def get_fixture(type, number = 1)
    fixture_file = File.join(File.dirname(__FILE__),
        '..', '..', 'fixtures',"rifcs-#{type}-#{number}.xml")
    File.open(fixture_file) { |f| f.read() }
  end

  it { should respond_to(:sets, :underlying_concept) }

  it "should handle writing empty metadata" do
    [nil, ''].each do |metadata|
      lambda do
        Miletus::Output::OAIPMH::Record.create(:metadata => metadata)
      end.should_not raise_error
    end
  end

  context "OAI Dublin Core" do

    it { should respond_to(:to_oai_dc) }

    it "should return nil if record cannot generate valid Dublin Core" do
      subject.to_oai_dc.should be_nil
    end

    context "should return valid OAI Dublin Core if provided with" do
      %w{collection party activity service}.each do |type|
        example "a RIF-CS #{type}" do
          subject.metadata = get_fixture(type)
          subject.should be_valid
          subject.to_oai_dc.should_not be_nil
          # Validate the XML
          dc_doc = Nokogiri::XML(subject.to_oai_dc)
          ns_by_prefix('oai_dc').schema.valid?(dc_doc).should be_true
        end
      end
    end

    it "should handle alternate RIF-CS names" do
      include Miletus::NamespaceHelper
      subject.metadata = get_fixture('party')
      subject.should be_valid
      subject.to_oai_dc.should_not be_nil
      # Validate the XML
      dc_doc = Nokogiri::XML(subject.to_oai_dc)
      title_nodes = dc_doc.xpath("//dc:title", ns_decl)
      title_nodes.map {|n| n.content }.should \
        == ["Dettrick, Timothy John", "Dettrick, Tim"]
    end

    it "should include descriptions when available" do
      include Miletus::NamespaceHelper
      subject.metadata = get_fixture('collection')
      subject.should be_valid
      subject.to_oai_dc.should_not be_nil
      # Validate the XML
      dc_doc = Nokogiri::XML(subject.to_oai_dc)
      desc_node = dc_doc.at_xpath("//dc:description", ns_decl)
      desc_node.content.should
        match(/14 adult estuarine crocodiles were captured/)
    end

    it "should include rights when available" do
      include Miletus::NamespaceHelper
      subject.metadata = get_fixture('collection', '1b')
      subject.should be_valid
      subject.to_oai_dc.should_not be_nil
      # Validate the XML
      dc_doc = Nokogiri::XML(subject.to_oai_dc)
      rights_elements = dc_doc.xpath("//dc:rights", ns_decl)
      rights_elements.should have(2).elements
      rights_elements.each do |e|
        e.content.should \
          match(/^(The data in this project|The data is the property of)/)
      end
    end

  end

  context "RIF-CS" do

    it { should respond_to(:to_rif) }

    it "should return nil if record cannot generate valid RIF-CS" do
      subject.to_rif.should be_nil
      subject.metadata = "<xml/>"
      subject.to_rif.should be_nil
    end

    context "should return valid RIF-CS if provided with" do
      %w{collection party activity service}.each do |type|
        example "a RIF-CS #{type}" do
          subject.metadata = get_fixture(type)
          subject.to_rif.should_not be_nil
          # Validate the XML
          rifcs_doc = Nokogiri::XML(subject.to_rif)
          ns_by_prefix('rif').schema.valid?(rifcs_doc).should be_true
        end
      end
    end

    it "should update dateModified when saved" do
      subject.metadata = get_fixture('party')
      subject.to_rif.should_not be_nil
      # Save
      subject.save!
      # Check time was updated
      rifcs_doc = Nokogiri::XML(subject.to_rif)
      rifcs_doc.at_xpath("//@dateModified", ns_decl).value.should\
        == subject.updated_at.iso8601
    end

  end

end
