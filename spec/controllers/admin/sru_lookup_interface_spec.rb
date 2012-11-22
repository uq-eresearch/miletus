require 'spec_helper'
require File.join(File.dirname(__FILE__), 'shared_examples')

describe Admin::SruLookupInterfacesController do
  it_behaves_like "an admin page"
  include_context "logged in as admin"
  render_views

  describe "GET index" do

    context "with a single SRU Interface" do
      before(:each) do
        Miletus::Harvest::SRU::Interface.create(
          :endpoint => 'http://example.test/sru')
      end

      it "is successful" do
        get :index
        response.should be_success
      end
    end

  end
end