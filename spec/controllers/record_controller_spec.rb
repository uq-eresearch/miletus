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
    subject do
      get 'index'
      response
    end

    context "when no concepts exist" do
      it { should be_success }
    end

    context "when concepts exist" do
      before(:each) do
        Miletus::Merge::Concept.create()
        Miletus::Merge::Concept.create().tap do |concept|
          concept.type = 'activity'
          concept.save!
        end
      end
      it { should be_success }
    end
  end

  describe "GET 'view'" do

    before(:each) do
      fixture_file = File.join(File.dirname(__FILE__),
        '..', 'fixtures',"rifcs-collection-1.xml")
      @concept = Miletus::Merge::Concept.create()
      @concept.facets.create(
        :metadata => File.open(fixture_file) { |f| f.read() }
      )
      @concept.reload
    end

    it "returns http success for uuid fetch" do
      get 'view', :uuid => @concept.uuid
      response.should be_success
    end

    it "returns http redirect for id fetch" do
      get 'view', :id => @concept.id
      response.should be_redirect
    end

    it "returns http success for id fetch when no uuid exists" do
      concept = Miletus::Merge::Concept.create()
      get 'view', :id => concept.id
      response.should be_success
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
