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
        Page.count.should == 1
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
        Page.count.should == 1
        get 'view', :name => 'index'
        response.should be_success
        response.body.should match(/#{expected_content}/)
      end
    end

  end

end
