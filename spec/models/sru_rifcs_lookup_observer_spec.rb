require 'spec_helper'

describe SruRifcsLookupObserver do

  subject { SruRifcsLookupObserver.instance }

  # Ensure that jobs execute immediately for these tests
  before(:each) { Delayed::Worker.delay_jobs = false }

  it { should respond_to(:after_save) }

  def get_fixture(type, number = 1)
    fixture_file = File.join(File.dirname(__FILE__),
        '..', 'fixtures',"rifcs-#{type}-#{number}.xml")
    File.open(fixture_file) { |f| f.read() }
  end

  it "should look up identifiers and keys" do
    # Create concept and facet
    xml = get_fixture('party', '1c')
    # Create mock SRU Interface with expectations
    sru_interface = double(Miletus::Harvest::SRU::Interface)
    sru_interface.stub(:endpoint).and_return('http://example.test/sru')
    sru_interface.should_receive(:suitable_type?).with('party').and_return(true)
    looked_up = []
    sru_interface.should_receive(:lookup_by_identifier).with(kind_of(String))\
      .exactly(3).times \
      .and_return do |ident|
        looked_up << ident
        nil
      end
    Miletus::Harvest::SRU::Interface.should_receive(:all).and_return(
      [sru_interface]
    )
    # Create concept
    concept = Miletus::Merge::Concept.create()
    # Create record to trigger lookup
    concept.facets.create(:metadata => Nokogiri::XML(xml).to_s)
    # Check values
    [
      'http://nla.gov.au/nla.party-1486629',
      'mirage.cmm.uq.edu.au/user/1',
      concept.reload.key
    ].each do |ident|
      looked_up.should include(ident)
    end
  end

  it "should do a new lookup when a facet is created" do
    VCR.use_cassette('nla_lookup_for_party_1c') do
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
