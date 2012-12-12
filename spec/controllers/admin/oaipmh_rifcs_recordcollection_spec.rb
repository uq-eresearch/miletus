require 'spec_helper'
require File.join(File.dirname(__FILE__), 'shared_examples')

describe Admin::RifcsOverOaipmhRecordCollectionsController do
  it_behaves_like "an admin page"
  include_context "logged in as admin"
  render_views

  describe "GET index" do
    context "with a single SRU Interface" do
      before(:each) do
        Miletus::Harvest::OAIPMH::RIFCS::RecordCollection.create(
          :endpoint => 'http://example.test/oai')
        get :index
      end

      it { should respond_with(:success) }
    end
  end

  describe "POST harvest" do
    before(:each) do
      Miletus::Harvest::OAIPMH::RIFCS.should_receive(:jobs).and_return([])
      post :harvest
    end

    it { should respond_with(:redirect) }
  end
end