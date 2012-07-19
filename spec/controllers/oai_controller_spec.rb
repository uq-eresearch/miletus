require 'spec_helper'

describe OaiController do

  NS_DECL = 'oai:http://www.openarchives.org/OAI/2.0/'

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

  end

end
