require 'spec_helper'

require 'miletus/harvest/oaipmh_rifcs/record'
require 'miletus/output/oaipmh/record'

describe RifcsRecordObserver do

  subject { RifcsRecordObserver.instance }

  it { should respond_to(:after_create, :after_update, :after_destroy) }

  it "should create a new output record for a new harvested record" do
    # New record should have been created on a delay, not immediately
    subject.should_receive(:delay).at_least(1).and_return(subject)
    # Load data from fixture
    fixture_file = File.join(File.dirname(__FILE__),
      '..', 'fixtures','rifcs-party-1.xml')
    xml = File.open(fixture_file) { |f| f.read }
    # Create record
    input_record = Miletus::Harvest::OAIPMH::RIFCS::Record.new.tap do |r|
      r.identifier = 'http://example.test/1'
      r.datestamp = Time.now
      doc = XML::Document.string(xml)
      r.metadata = doc.import(XML::Node.new('metadata')) << doc.root
      r.save!
    end
    # Run hook
    subject.after_create(input_record)
    # A new record should exist as a result
    output_record = Miletus::Output::OAIPMH::Record.find(:first)
    output_record.should_not be(nil)
    output_record.to_rif.should_not be(nil)
  end

end
