require 'spec_helper'

require 'libxml'

describe OaiController do

  let(:ns_decl) do
    Miletus::NamespaceHelper::ns_decl
  end

  describe "GET 'index'" do
    it "returns application level error with no parameters" do
      get 'index'
      response.should be_success
      xml = Nokogiri::XML(response.body).root
      error_node = xml.at_xpath('//oai:error/@code', ns_decl)
      error_node.value.should == 'badVerb'
    end

    it "responds to the Identify verb" do
      get 'index', { 'verb' => 'Identify' }
      response.should be_success
      xml = Nokogiri::XML(response.body).root
      identify_node = xml.at_xpath('//oai:Identify', ns_decl)
      identify_node.should_not be_nil
      protocol_node = xml.at_xpath('//oai:protocolVersion', ns_decl)
      protocol_node.content.should == "2.0"
      baseurl_node = xml.at_xpath('//oai:baseURL', ns_decl)
      baseurl_node.content.should == "http://test.host/oai"
      repo_id_node = xml.at_xpath('//oaii:repositoryIdentifier', ns_decl)
      repo_id_node.content.should == "test.host"
    end

    it "lists RIF-CS as a metadata format" do
      get 'index', { 'verb' => 'ListMetadataFormats' }
      response.should be_success
      xml = Nokogiri::XML(response.body).root
      prefix_nodes = xml.xpath('//oai:metadataPrefix', ns_decl)
      prefix_nodes.map{|e| e.content}.should include('rif')
    end

    describe "when no records exist" do

      describe "ListIdentifiers" do
        it "should respond with \"noRecordsMatch\" " do
          get 'index', { 'verb' => 'ListIdentifiers' }
          response.should be_success
          xml = Nokogiri::XML(response.body).root
          error_node = xml.at_xpath('//oai:error/@code', ns_decl)
          error_node.value.should == 'noRecordsMatch'
        end
      end

      describe "ListRecords" do
        it "should respond with \"noRecordsMatch\" " do
          get 'index', { 'verb' => 'ListRecords' }
          response.should be_success
          xml = Nokogiri::XML(response.body).root
          error_node = xml.at_xpath('//oai:error/@code', ns_decl)
          error_node.value.should == 'noRecordsMatch'
        end
      end

    end

    describe "when records exist" do

      before(:each) do
        fixture_file = File.join(File.dirname(__FILE__),
          '..', 'fixtures','rifcs-party-1.xml')
        Miletus::Output::OAIPMH::Record.new(
          :metadata => File.open(fixture_file) { |f| f.read() }
        ).save!
        Miletus::Output::OAIPMH::Record.count.should > 0
      end

      describe "ListIdentifiers" do
        it "should not respond with \"noRecordsMatch\" " do
          get 'index', { 'verb' => 'ListIdentifiers' }
          response.should be_success
          xml = Nokogiri::XML(response.body).root
          xml.at_xpath('//oai:error', ns_decl).should be_nil
          xml.at_xpath('//oai:ListIdentifiers', ns_decl).should_not be_nil
        end
      end

      describe "ListRecords" do
        it "should respond with the records that currently exist" do
          Miletus::Output::OAIPMH::Record.count.should == 1
          get 'index', { 'verb' => 'ListRecords' }
          response.should be_success
          xml = Nokogiri::XML(response.body).root
          xml.at_xpath('//oai:error', ns_decl).should be_nil
          xml.at_xpath('//oai:ListRecords', ns_decl).should_not be_nil
          xml.at_xpath('//oai:record', ns_decl).should_not be_nil
          xml.xpath('//oai:header/oai:setSpec', ns_decl).count.should > 1
        end

        it "should put records in sets" do
          Miletus::Output::OAIPMH::Record.count.should == 1
          get 'index', {
            'verb' => 'ListRecords',
            'set' => 'party:identifier:AU-QU' }
          response.should be_success
          xml = Nokogiri::XML(response.body).root
          xml.at_xpath('//oai:error', ns_decl).should be_nil
          xml.at_xpath('//oai:ListRecords', ns_decl).should_not be_nil
          xml.xpath('//oai:record', ns_decl).count.should == 1
          xml.xpath('//oai:header/oai:setSpec', ns_decl).count.should > 1
          get 'index', {
            'verb' => 'ListRecords',
            'set' => 'nosuchset' }
          xml = Nokogiri::XML(response.body).root
          response.should be_success
          error_node = xml.at_xpath('//oai:error/@code', ns_decl)
          error_node.should_not be_nil
          error_node.value.should == 'noRecordsMatch'
        end
      end

      describe "ListSets" do
        it "should not respond with an error" do
          get 'index', { 'verb' => 'ListSets' }
          response.should be_success
          xml = Nokogiri::XML(response.body).root
          xml.at_xpath('//oai:error', ns_decl).should be_nil
          xml.at_xpath('//oai:ListSets', ns_decl).should_not be_nil
        end

        it "should respond with any sets that exist" do
          Miletus::Output::OAIPMH::Set.count.should > 0
          get 'index', { 'verb' => 'ListSets' }
          response.should be_success
          xml = Nokogiri::XML(response.body).root
          xml.at_xpath('//oai:ListSets/oai:set', ns_decl).should_not be_nil
        end
      end

    end

  end

end
