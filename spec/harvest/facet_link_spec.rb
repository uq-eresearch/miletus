require 'spec_helper'

describe Miletus::Harvest::FacetLink do

  it { should respond_to(:facet, :harvest_record) }

  describe "integration with Miletus::Harvest::Document::RIFCS" do
    let :fixture_url do
      fixture_file = File.expand_path(
        File.join(File.dirname(__FILE__),
          '..', 'fixtures', 'rifcs-activity-1.xml'))
      'file://%s' % fixture_file
    end

    it "should use with add, update and delete" do
      # Disable delayed run for hooks
      RifcsRecordObserver.stub(:run_job).and_return { |j| j.run }
      VCR.use_cassette('lookup_rifcs_schema') do
        ns_by_prefix('rif').schema # Pre-cache so we can use later
      end
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

end
