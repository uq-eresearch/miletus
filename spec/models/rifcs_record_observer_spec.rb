require 'spec_helper'

require 'miletus'

describe RifcsRecordObserver do

  subject { RifcsRecordObserver.instance }

  it { should respond_to(:after_create, :after_update, :after_destroy) }

  let(:ns_decl) do
    Miletus::Output::OAIPMH::NamespaceHelper::ns_decl
  end

  let (:create_input_record) {
    # Load data from fixture
    fixture_file = File.join(File.dirname(__FILE__),
      '..', 'fixtures','rifcs-party-1.xml')
    xml = File.open(fixture_file) { |f| f.read }
    # Create record
    Miletus::Harvest::OAIPMH::RIFCS::Record.new.tap do |r|
      r.identifier = 'http://example.test/1'
      r.datestamp = Time.now
      doc = XML::Document.string(xml)
      r.metadata = doc.import(XML::Node.new('metadata')) << doc.root
      r.save!
    end
  }

  it "should create a new output record for a new harvested record" do
    input_record = create_input_record
    # Run hook - which will happen as part of the environment
    # subject.after_create(input_record)
    # Work should happen on a delay
    output_record = Miletus::Output::OAIPMH::Record.find(:first)
    output_record.should be(nil)
    # Run delayed jobs
    Delayed::Worker.new.work_off
    # A new record should exist as a result
    output_record = Miletus::Output::OAIPMH::Record.find(:first)
    output_record.should_not be(nil)
    output_record.to_rif.should_not be(nil)
  end

  it "should update output records when the harvested record changes" do
    input_record = create_input_record
    # Run hook - which will happen as part of the environment
    # subject.after_create(input_record)
    Delayed::Worker.new.work_off
    Miletus::Output::OAIPMH::Record.all.count.should == 1
    # A new record should exist as a result
    output_record = Miletus::Output::OAIPMH::Record.find(:first)
    output_record.should_not be(nil)
    output_record.to_rif.should_not be(nil)
    # Change input record
    input_record.reload
    input_record.should_not be_readonly
    doc = input_record.metadata
    nodes = doc.find("//rif:namePart[@type='given'][text()='John']", ns_decl)
    nodes.each do |e|
      e.remove!
    end
    input_record.should_not be_readonly
    input_record.metadata = doc
    input_record.should_not be_readonly
    input_record.save!
    # Run hook - which will happen as part of the environment
    # subject.after_update(input_record)
    Delayed::Worker.new.work_off
    # Check the record was updated
    Miletus::Output::OAIPMH::Record.all.count.should == 1
    output_record = Miletus::Output::OAIPMH::Record.find(:first)
    rifcs_doc = XML::Document.string(output_record.to_rif)
    rifcs_doc.find("//rif:namePart[@type='given'][text()='John']",
      ns_decl).should be_empty
  end

end
