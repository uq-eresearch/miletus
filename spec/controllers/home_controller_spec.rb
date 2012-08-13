require 'spec_helper'

describe HomeController do

  subject { HomeController.new }

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end

    it "should run without request parameters" do
      lambda { subject.index }.should_not raise_error
    end

  end

end
