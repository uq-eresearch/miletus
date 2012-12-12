require 'spec_helper'
require File.join(File.dirname(__FILE__), 'shared_examples')

describe Admin::DirectRdcAtomDocumentsController do
  it_behaves_like "an admin page"
  include_context "logged in as admin"
  render_views

  describe "GET index" do
    context "with a single RDC Atom Document" do
      before(:each) do
        Miletus::Harvest::Document::RDCAtom.create(
          :url => 'http://example.test/doc.atom')
        get :index
      end

      it { should respond_with(:success) }
    end
  end
end