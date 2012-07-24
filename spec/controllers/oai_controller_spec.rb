require 'spec_helper'

require 'libxml'
require 'miletus/output/oaipmh/record'

describe OaiController do

  describe "GET 'index'" do
    it "returns application level error with no parameters" do
      get 'index'
      response.should be_success
      xml = XML::Document.string(response.body).root
      xml.find_first('//oai:error/@code', NS_DECL).value.should == 'badVerb'
    end

    it "responds to the Identify verb" do
      get 'index', { 'verb' => 'Identify' }
      response.should be_success
      xml = XML::Document.string(response.body).root
      xml.find_first('//oai:Identify', NS_DECL).should_not be(nil)
      xml.find_first('//oai:protocolVersion', NS_DECL).content.should == "2.0"
      xml.find_first('//oai:baseURL', NS_DECL).content.should \
        == "http://test.host/oai"
      xml.find_first('//oaii:repositoryIdentifier', NS_DECL).content.should \
        == "test.host"
    end

    it "lists RIF-CS as a metadata format" do
      get 'index', { 'verb' => 'ListMetadataFormats' }
      response.should be_success
      xml = XML::Document.string(response.body).root
      prefixes = xml.find('//oai:metadataPrefix', NS_DECL).map{|e| e.content}
      prefixes.should include('rif')
    end

    describe "when no records exist" do

      it "should respond to ListIdentifiers with \"noRecordsMatch\" " do
        get 'index', { 'verb' => 'ListIdentifiers' }
        response.should be_success
        xml = XML::Document.string(response.body).root
        xml.find_first('//oai:error/@code', NS_DECL).value.should == 'noRecordsMatch'
      end

      it "should respond to ListRecords with \"noRecordsMatch\" " do
        get 'index', { 'verb' => 'ListRecords' }
        response.should be_success
        xml = XML::Document.string(response.body).root
        xml.find_first('//oai:error/@code', NS_DECL).value.should == 'noRecordsMatch'
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

      it "should not respond to ListIdentifiers with \"noRecordsMatch\" " do
        get 'index', { 'verb' => 'ListIdentifiers' }
        response.should be_success
        xml = XML::Document.string(response.body).root
        xml.find_first('//oai:error', NS_DECL).should be(nil)
        xml.find_first('//oai:ListIdentifiers', NS_DECL).should_not be(nil)
      end

      it "should not respond to ListRecords with \"noRecordsMatch\" " do
        get 'index', { 'verb' => 'ListRecords' }
        response.should be_success
        xml = XML::Document.string(response.body).root
        xml.find_first('//oai:error', NS_DECL).should be(nil)
        xml.find_first('//oai:ListRecords', NS_DECL).should_not be(nil)
      end

    end

  end

end
