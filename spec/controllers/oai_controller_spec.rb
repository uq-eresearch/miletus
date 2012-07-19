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

  end

end
