require 'spec_helper'

describe SeoController do

  describe "GET 'robots'" do

    render_views

    it "should be provided by seo#robots" do
      { :get => "/robots.txt" }.should route_to(
        :controller => 'seo',
        :action => 'robots')
    end

    it "should contain a link to the sitemap" do
      get 'robots'
      response.should be_success
      response.body.should include("Sitemap: http://test.host/siteindex.xml")
    end

  end

  describe "GET 'siteindex'" do

    it "should be provided by seo#robots" do
      { :get => "/siteindex.xml" }.should route_to(
        :controller => 'seo',
        :action => 'siteindex')
    end

    it "should be a valid sitemap index" do
      get 'siteindex'
      response.should be_success
      doc = Nokogiri::XML(response.body)
      ns_by_prefix('siteindex').schema.validate(doc).should == []
    end

  end

  describe "GET 'sitemap'" do

    it "should be provided by seo#robots" do
      { :get => "/main.sitemap" }.should route_to(
        :controller => 'seo',
        :action => 'sitemap')
    end

    it "should be a valid sitemap for core pages" do
      get 'sitemap'
      response.should be_success
      doc = Nokogiri::XML(response.body)
      ns_by_prefix('sitemap').schema.validate(doc).should == []
    end

  end


end
