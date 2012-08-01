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
    # A new record should exist as a result
    output_record = Miletus::Output::OAIPMH::Record.find(:first)
    output_record.should_not be(nil)
    output_record.to_rif.should_not be(nil)
  end

  it "should update an existing output record when a concept updates" do
    # Disable delayed run for hooks
    RifcsRecordObserver.stub(:run_job).and_return { |j| j.run }
    concept = create_concept
    # Run hook - which will happen as part of the environment
    # subject.after_create(input_record)
    # A new record should exist as a result
    output_record = Miletus::Output::OAIPMH::Record.find(:first)
    output_record.should_not be(nil)
    output_record.to_rif.should_not be(nil)
    # Change facet
    facet = concept.facets.first
    doc = Nokogiri::XML(facet.metadata)
    nodes = doc.xpath("//rif:namePart[@type='given'][text()='John']",
      'rif' => 'http://ands.org.au/standards/rif-cs/registryObjects')
    nodes.each do |e|
      e.remove
    end
    facet.metadata = doc
    facet.save!
    # The concept should update as a result
    output_record = Miletus::Output::OAIPMH::Record.find(:first)
    output_record.should_not be_nil
    output_record.to_rif.should_not be_nil
    rifcs_doc = Nokogiri::XML::Document.parse(output_record.to_rif)
    rifcs_doc.xpath("//rif:namePart[@type='given'][text()='John']",
      'rif' => 'http://ands.org.au/standards/rif-cs/registryObjects')\
       .should be_empty
  end

  it "should mark output records as deleted when concepts have no entries" do
    # Disable delayed run for hooks
    RifcsRecordObserver.stub(:run_job).and_return { |j| j.run }
    concept = create_concept
    # Run hook - which will happen as part of the environment
    # subject.after_create(input_record)
    # A new record should exist as a result
    output_record = Miletus::Output::OAIPMH::Record.find(:first)
    output_record.should_not be(nil)
    output_record.to_rif.should_not be(nil)
    # Delete facet
    concept.facets.first.destroy
    Miletus::Merge::Facet.all.count.should == 0
    # The record should be marked deleted as a result
    output_record = Miletus::Output::OAIPMH::Record.find(:first)
    output_record.should_not be_nil
    output_record.should be_deleted
  end


end
