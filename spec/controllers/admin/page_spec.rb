require 'spec_helper'
require File.join(File.dirname(__FILE__), 'shared_examples')

describe Admin::PagesController do
  it_behaves_like "an admin page"
  include_context "logged in as admin"

  render_views

  describe "GET show" do

    context "with a single empty Page" do
      before(:each) { @page = Page.create }
      it "is successful" do
        get :show, :id => @page.id
        response.should be_success
      end
    end

    context "with a single populated Page" do
      before(:each) do
        md_content = <<-EOH
          ## A heading

          A paragraph leading to an:

           * unordered
           * linked
           * list

        EOH
        @page = Page.create :name => 'foo', :content => md_content
      end

      it "is successful" do
        get :show, :id => @page.id
        response.should be_success
      end
    end

  end

end