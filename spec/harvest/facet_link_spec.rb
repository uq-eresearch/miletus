require 'spec_helper'

describe Miletus::Harvest::FacetLink do

  it { should respond_to(:facet, :harvest_record) }

  # Ensure that jobs execute immediately for these tests
  before(:each) { Delayed::Worker.delay_jobs = false }

  describe "integration with Miletus::Harvest::Document::RIFCS" do
    let :fixture_url do
      fixture_file = File.expand_path(
        File.join(File.dirname(__FILE__),
          '..', 'fixtures', 'rifcs-activity-1.xml'))
      'file://%s' % fixture_file
    end

    it "should use with add, update and delete" do
      # Create new doc
      doc = Miletus::Harvest::Document::RIFCS.new
      VCR.use_cassette('ands_rifcs_example') do
        doc.should respond_to(:facet_links)
        doc.url = \
          'http://services.ands.org.au/documentation/rifcs/example/rif.xml'
        doc.save!
        doc.should have(0).facet_links
        # Populate record data and check that links are created
        doc.fetch
      end
      doc.should have(4).facet_links
      doc.facet_links.pluck(:facet_id).uniq.count.should be == 4
      doc.url = fixture_url
      doc.fetch
      doc.should have(1).facet_links
      # The links should delete when the record data does
      doc.document.clear
      doc.should be_changed
      doc.save!
      doc.should have(0).facet_links
    end
  end

  describe "integration with Miletus::Harvest::Document::RDCAtom" do

    it "should respond to :facet_links" do
      Miletus::Harvest::Document::RDCAtom.respond_to?(:facet_links)
    end

  end

  describe "integration with Miletus::Harvest::OAIPMH::RIFCS::Record" do
    let(:fixture) do
      # Load data from fixture
      fixture_file = File.join(File.dirname(__FILE__),
        '..', 'fixtures',"rifcs-party-1.xml")
      xml = File.open(fixture_file) { |f| f.read }
      # Create collection
      rc = Miletus::Harvest::OAIPMH::RIFCS::RecordCollection.create(
        :endpoint => 'http://example.test/oai'
      )
      # Create record
      Miletus::Harvest::OAIPMH::RIFCS::Record.new.tap do |r|
        r.record_collection = rc
        r.identifier = 'http://example.test/1'
        r.datestamp = Time.now
        r.metadata = Nokogiri::XML(xml).tap do |doc|
          old_root = doc.root
          doc.root = Nokogiri::XML::Node.new('metadata', doc)
          doc.root << old_root
        end.to_s
      end
    end

    it "should create a new concept for a new harvested record" do
      input_record = fixture
      input_record.should respond_to(:facet_links)
      input_record.save!
      # Check that facet links have been created
      input_record.should have(1).facet_links
      input_record.deleted = true
      input_record.save!
      # Check that facet links have been created
      input_record.should have(0).facet_links
    end
  end

end
