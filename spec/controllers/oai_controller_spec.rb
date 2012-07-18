require 'spec_helper'

describe OaiController do

  describe "GET 'index'" do
    it "returns application level error with no parameters" do
      get 'index'
      response.should be_success
      xml = XML::Document.string(response.body).root
      xml.find_first('//@code').value.should == 'badVerb'
    end
  end

end
