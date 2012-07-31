require 'spec_helper'

require 'miletus'

describe OaipmhOutputObserver do

  subject { OaipmhOutputObserver.instance }

  it { should respond_to(:after_update) }

  let(:ns_decl) do
    Miletus::Output::OAIPMH::NamespaceHelper::ns_decl
  end

  def create_concept(type = 'party', fixture_id = 1)
    # Load data from fixture
    fixture_file = File.join(File.dirname(__FILE__),
      '..', 'fixtures',"rifcs-#{type}-#{fixture_id}.xml")
    xml = File.open(fixture_file) { |f| f.read }
    # Create concept
    concept = Miletus::Merge::Concept.create()
    # Create record
    concept.facets.create(
      :metadata => Nokogiri::XML(xml).tap do |doc|
        old_root = doc.root
        doc.root = Nokogiri::XML::Node.new('metadata', doc)
        doc.root << old_root
      end.to_s
    )
    concept
  end

  it "should create a new output record for a new concept" do
    # Disable delayed run for hooks
    RifcsRecordObserver.stub(:run_job).and_return { |j| j.run }
    concept = create_concept
    # Run hook - which will happen as part of the environment
    # subject.after_create(input_record)
    # A new concept should exist as a result
    output_record = Miletus::Output::OAIPMH::Record.find(:first)
    output_record.should_not be(nil)
    output_record.to_rif.should_not be(nil)
  end


end
