require 'spec_helper'

describe SruRifcsLookupObserver do

  subject { SruRifcsLookupObserver.instance }

  it { should respond_to(:after_save) }

  def get_fixture(type, number = 1)
    fixture_file = File.join(File.dirname(__FILE__),
        '..', 'fixtures',"rifcs-#{type}-#{number}.xml")
    File.open(fixture_file) { |f| f.read() }
  end

  it "should normally run jobs using delayed_job" do
    test_job = Object.new.tap do |obj|
      obj.should_receive(:delay).and_return do
        Object.new.tap {|o| o.should_receive(:run)}
      end
    end
    SruRifcsLookupObserver.run_job(test_job)
  end

  it "should do a new lookup when a facet is created" do
    VCR.use_cassette('nla_lookup_for_party_1c') do
      # Disable delayed run for hooks
      SruRifcsLookupObserver.stub(:run_job).and_return { |j| j.run }
      # Create concept and facet
      xml = get_fixture('party', '1c')
      # Create SRU Interface
      Miletus::Harvest::SRU::Interface.create(
        :endpoint => 'http://www.nla.gov.au/apps/srw/search/peopleaustralia',
        :schema => ns_by_prefix('rif').uri)
      # Create concept
      concept = Miletus::Merge::Concept.create()
      # Create record
      concept.facets.create(:metadata => Nokogiri::XML(xml).to_s)
      concept.should have(2).facets
      concept.facets.any?{ |f| f.to_rif.nil? }.should be_false
    end
  end

end
