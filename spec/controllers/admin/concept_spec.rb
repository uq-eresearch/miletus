require 'spec_helper'
require File.join(File.dirname(__FILE__), 'shared_examples')

describe Admin::ConceptsController do
  it_behaves_like "an admin page"
  include_context "logged in as admin"
  render_views

  describe "GET index" do
    context "when a single facetless concept exists" do
      before(:each) do
        Miletus::Merge::Concept.create()
        get :index
      end

      it { should respond_with(:success) }
    end
  end

  describe "GET show" do
    context "for a single facetless concept" do
      before(:each) do
        get :show, :id => Miletus::Merge::Concept.create.id
      end

      it { should respond_with(:success) }
    end
  end

  describe "POST batch_action - merge" do
    context "for two single facetless concepts" do
      before(:each) do
        concepts = 2.times.collect { Miletus::Merge::Concept.create() }
        post :batch_action,
          :batch_action => 'merge',
          :collection_selection => concepts.map(&:id)
      end

      it { should respond_with(:redirect) }

      it "should result in only one concept" do
        Miletus::Merge::Concept.count.should be == 1
      end
    end
  end

  describe "POST reindex" do
    before(:each) do
      post :reindex
    end

    it { should respond_with(:redirect) }
  end

  describe "POST recheck_sru" do
    before(:each) do
      post :recheck_sru
    end

    it { should respond_with(:redirect) }
  end

end