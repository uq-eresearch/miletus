require 'spec_helper'
require File.join(File.dirname(__FILE__), 'shared_examples')

describe Admin::DirectRifCsDocumentsController do
  it_behaves_like "an admin page"
  include_context "logged in as admin"
  render_views

  describe "GET index" do
    context "with a single RIF-CS Document" do
      before(:each) do
        Miletus::Harvest::Document::RIFCS.create(
          :url => 'http://example.test/doc.rifcs.xml')
      end

      it "is successful" do
        get :index
        response.should be_success
      end
    end
  end
end