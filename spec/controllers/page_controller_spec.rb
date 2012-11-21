require 'spec_helper'

describe PageController do

  describe "Front Page" do

    it "should be provided by page#view" do
      { :get => "/" }.should route_to(
        :controller => 'page',
        :action => 'view',
        :name => 'index')
    end

    it "returns not found unless created" do
      get 'view', :name => 'index'
      response.should be_not_found
    end

    context 'when an "index" page has been created' do
      render_views

      subject { Page.new(:name => 'index', :content => "Hello World!") }

      it "should return the provided content" do
        subject.save!
        Page.count.should be == 1
        get 'view', :name => 'index'
        response.should be_success
        response.body.should match(/#{subject.content}/)
      end
    end

    context 'when an "index" page has markdown content' do
      render_views

      subject {
        Page.new(:name => 'index', :content => "Markdown is *awesome*!")
      }

      let(:expected_content) do
        Regexp.escape(
          Redcarpet::Markdown.new(Redcarpet::Render::XHTML).render(
           subject.content
          )
        )
      end

      it "should return the rendered content" do
        subject.save!
        Page.count.should be == 1
        get 'view', :name => 'index'
        response.should be_success
        response.body.should match(/#{expected_content}/)
      end
    end

  end

  describe "sitemap" do

    it "should be provided by page#sitemap" do
      { :get => "/pages.sitemap" }.should route_to(
        :controller => 'page',
        :action => 'sitemap')
    end

    it "should return a not found if no records exist XML sitemap" do
      get 'sitemap'
      response.should be_not_found
    end

    it "returns a valid XML sitemap for all existing pages" do
      Page.create(:name => 'index', :content => "Hello World!")
      Page.create(:name => 'test', :content => "Test Page.")
      Page.count.should be == 2

      get 'sitemap'
      response.should be_success
      doc = Nokogiri::XML(response.body)
      ns_by_prefix('sitemap').schema.validate(doc).should == []
    end

  end

  describe "credits" do

    it "should be provided by page#credits" do
      { :get => "/credits" }.should route_to(
        :controller => 'page',
        :action => 'credits')
    end

    it "should return the credits page" do
      get 'credits'
      response.should be_success
    end

  end


end
