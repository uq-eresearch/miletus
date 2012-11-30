require 'spec_helper'

describe Admin::ConceptsController do
  render_views

  before(:each) do
    @user = AdminUser.find_by_email!('admin@example.com')
    sign_in @user
  end

  describe "GET index" do

    context "when no concepts exist" do
      before(:each) { get :index }

      it "is successful" do
        response.should be_success
      end
    end

    context "when a single facetless concept exists" do
      before(:each) do
        Miletus::Merge::Concept.create()
        get :index
      end

      it "is successful" do
        response.should be_success
      end
    end
  end

  describe "GET show" do

    context "for a single facetless concept" do
      before(:each) do
        get :show, :id => Miletus::Merge::Concept.create.id
      end

      it "is successful" do
        response.should be_success
      end
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

      it "is successful" do
        response.should be_redirect
        Miletus::Merge::Concept.count.should be == 1
      end
    end

  end

end