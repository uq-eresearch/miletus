require 'spec_helper'
require 'time'

describe Miletus::Merge::Facet do

  def get_fixture(type, number = 1)
    fixture_file = File.join(File.dirname(__FILE__),
        '..', 'fixtures',"rifcs-#{type}-#{number}.xml")
    File.open(fixture_file) { |f| f.read() }
  end

  subject do
    concept = Miletus::Merge::Concept.create
    concept.facets.new
  end

  describe "class methods" do
    subject { described_class }
    it { should respond_to(:create_or_update_by_metadata) }
  end

  it { should respond_to(:concept) }

  it "should handle writing empty metadata" do
    [nil, ''].each do |metadata|
      lambda do
        subject.metadata = metadata
        subject.save!
      end.should_not raise_error
    end
  end

  it "should destroy the concept if it is the last facet left" do
    subject.save!
    concept = subject.concept
    second_facet = concept.facets.create
    # Reload concept again for latest data
    concept.reload
    concept.should have(2).facets
    # Destroy one facet
    second_facet.destroy
    # Reload concept again for latest data
    concept.reload
    concept.should_not be_nil
    concept.should have(1).facets
    # Destroy last facet
    subject.destroy
    # Concept should no longer exist
    lambda { concept.reload }.should raise_error(ActiveRecord::RecordNotFound)
  end

  context "RIF-CS" do

    it { should respond_to(:to_rif) }

    it "should return nil if record cannot generate valid RIF-CS" do
      subject.to_rif.should be_nil
      subject.metadata = "<xml/>"
      subject.to_rif.should be_nil
    end

    context "should return valid RIF-CS if provided with" do
      %w{collection party activity service}.each do |type|
        example "a RIF-CS #{type}" do
          subject.metadata = get_fixture(type)
          subject.to_rif.should_not be_nil
          # Validate the XML
          rifcs_doc = Nokogiri::XML(subject.to_rif)
          ns_by_prefix('rif').schema.valid?(rifcs_doc).should be_true
        end
      end
    end

    it "should update dateModified to be the same as :updated_at" do
      subject.metadata = get_fixture('party')
      subject.to_rif.should_not be_nil
      # Save
      subject.save!
      # Check time was updated
      rifcs_doc = Nokogiri::XML(subject.to_rif)
      rifcs_doc.at_xpath("//@dateModified", ns_decl).value.should\
        == subject.updated_at.iso8601
    end

    it "should translate RIF-CS 1.2 rights elements to 1.3" do
      include Miletus::NamespaceHelper
      subject.metadata = get_fixture('collection')
      subject.to_rif.should_not be_nil
      subject.save!
      # Check the XML was converted
      rifcs_doc = Nokogiri::XML(subject.to_rif)
      rifcs_doc.at_xpath("//rif:rights", ns_decl).should_not be(nil)
      rifcs_doc.at_xpath("//rif:rights/rif:accessRights",
        ns_decl).content.should match(/^The data in this project/)
      rifcs_doc.at_xpath("//rif:rights/rif:rightsStatement",
        ns_decl).content.should match(/^The data is the property of/)
    end

  end

end
