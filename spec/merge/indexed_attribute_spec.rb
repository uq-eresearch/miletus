require 'spec_helper'

describe Miletus::Merge::IndexedAttribute do

  it { should respond_to(:concept, :key, :value) }

  describe "class" do

    subject { described_class }

    it { should respond_to(:update_for_concept) }

    describe "#update_for_concept" do

      it "should add sets of values" do
        concept = Miletus::Merge::Concept.create()
        subject.update_for_concept(concept, 'k', 10.upto(20).map(&:to_s))
        subject.where(:concept_id => concept.id, :key => 'k').pluck(:value)\
          .sort.should be == 10.upto(20).map(&:to_s).sort
      end

      it "should update sets of values leaving no old values" do
        concept = Miletus::Merge::Concept.create()
        subject.update_for_concept(concept, 'k', 10.upto(20).map(&:to_s))
        subject.update_for_concept(concept, 'k', 15.upto(25).map(&:to_s))
        subject.where(:concept_id => concept.id, :key => 'k').pluck(:value)\
          .sort.should be == 15.upto(25).map(&:to_s).map(&:to_s).sort
      end

    end

  end


end