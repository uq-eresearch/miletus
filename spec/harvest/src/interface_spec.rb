require 'spec_helper'

describe Miletus::Harvest::SRU::Interface do

  it { should respond_to(:endpoint, :schema, :exclude_xpaths) }

  it "should lookup nodes from SRU endpoints" do
    test_identifier = 'http://nla.gov.au/nla.party-1480554'
    VCR.use_cassette('nla_lookup_for_party_1480554') do
      # Create SRU Interface
      # http://nla.gov.au/nla.party-1480554
      interface = Miletus::Harvest::SRU::Interface.create(
        :endpoint => 'http://www.nla.gov.au/apps/srw/search/peopleaustralia',
        :schema => ns_by_prefix('rif').uri)
      xml = interface.lookup_by_identifier(test_identifier)
      xml.should_not be_nil
      Nokogiri::XML(xml).at_xpath('//rif:identifier[@type="AU-ANL:PEAU"]',
        ns_decl).content.strip.should be == test_identifier
      Nokogiri::XML(xml).at_xpath('//rif:namePart[@type="family"]',
        ns_decl).content.strip.should == 'Drennan'
    end
  end

  it "should be able to remove unneeded nodes" do
    test_identifier = 'http://nla.gov.au/nla.party-1480554'
    VCR.use_cassette('nla_lookup_for_party_1480554') do
      # Create SRU Interface
      # http://nla.gov.au/nla.party-1480554
      interface = Miletus::Harvest::SRU::Interface.create(
        :endpoint => 'http://www.nla.gov.au/apps/srw/search/peopleaustralia',
        :schema => ns_by_prefix('rif').uri,
        :exclude_xpaths => [
          '//rif:registryObject/*/*[not(local-name()="identifier")]',
          '//rif:identifier[not(@type="AU-ANL:PEAU")]'
        ])
      xml = interface.lookup_by_identifier(test_identifier)
      xml.should_not be_nil
      Nokogiri::XML(xml).at_xpath('//rif:identifier[@type="AU-ANL:PEAU"]',
        ns_decl).content.strip.should be == test_identifier
      Nokogiri::XML(xml).at_xpath('//rif:namePart[@type="family"]',
        ns_decl).should be_nil
    end
  end

  it "should take input for :exclude_xpaths via :exclude_xpaths_string" do
    interface = Miletus::Harvest::SRU::Interface.create(
      :endpoint => 'http://www.nla.gov.au/apps/srw/search/peopleaustralia',
      :schema => ns_by_prefix('rif').uri,
      :exclude_xpaths_string => <<-EOH
        //rif:registryObject/*/*[not(local-name()=\"identifier\")]
        //rif:identifier[not(@type=\"AU-ANL:PEAU\")]
      EOH
      )
    interface.exclude_xpaths.should be_a Array
    interface.exclude_xpaths.should be == [
      '//rif:registryObject/*/*[not(local-name()="identifier")]',
      '//rif:identifier[not(@type="AU-ANL:PEAU")]'
    ]
    interface.exclude_xpaths_string.should be == \
      interface.exclude_xpaths.join("\n")
  end

end