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
          :schema => 'rif',
          :endpoint => 'http://example.test/sru')
        get :index
      end

      it { should respond_with(:success) }
    end
  end
end