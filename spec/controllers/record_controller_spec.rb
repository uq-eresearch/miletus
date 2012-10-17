require 'spec_helper'

describe RecordController do

  def get_fixture(type, number = 1)
    fixture_file = File.join(File.dirname(__FILE__),
        '..', 'fixtures',"rifcs-#{type}-#{number}.xml")
    File.open(fixture_file) { |f| f.read() }
  end


  subject { RecordController.new }

  describe "routing" do

    it "should provide /browse with #index" do
      {
        :get => "/browse"
      }.should route_to(:controller => 'record', :action => 'index')
    end

  end

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

  describe "GET 'sitemap'" do

    it "should return a not found if no records exist XML sitemap" do
      get 'sitemap'
      response.should be_not_found
    end

    it "returns a valid XML sitemap for all existing records" do
      concept = Miletus::Merge::Concept.create()
      [1, '1d'].map{|n| get_fixture('party', n)}.each do |fixture_xml|
        concept.facets.create(:metadata => fixture_xml)
      end

      get 'sitemap'
      response.should be_success
      doc = Nokogiri::XML(response.body)
      ns_by_prefix('sitemap').schema.validate(doc).should == []
    end

  end

end
