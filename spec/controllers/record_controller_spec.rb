require 'spec_helper'

describe RecordController do

  subject { RecordController.new }

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end

    it "should run without request parameters" do
      lambda { subject.index }.should_not raise_error
    end

  end

  describe "GET 'gexf'" do
    it "returns valid GEXF graph" do
      get 'gexf'
      response.should be_success
      doc = Nokogiri::XML(response.body)
      ns_by_prefix('gexf').schema.validate(doc).should == []
    end
  end

end
