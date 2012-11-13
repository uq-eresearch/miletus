require 'spec_helper'

require 'cgi'

describe RecordHelper do

  subject { Object.new.extend(ERB::Util).extend(RecordHelper) }

  def get_fixture(type, number = 1)
    fixture_file = File.join(File.dirname(__FILE__),
        '..', 'fixtures',"rifcs-#{type}-#{number}.xml")
    File.open(fixture_file) { |f| f.read() }
  end

  describe "annotated_xml" do
    it "should not throw exceptions when used on a simple RIF-CS document" do
      doc = Nokogiri::XML(get_fixture('party', 1))
      lambda { subject.annotated_xml(doc) }.should_not raise_error
    end
  end

  describe "email_addresses" do
    it "produces a list of email addresses for a RIF-CS document" do
      doc = Nokogiri::XML(get_fixture('party', '1d'))
      subject.email_addresses(doc).should == ["td@foo.com", "td@bar.net"]
    end
  end

  describe "email_uris" do
    it "produces a list of obfuscated email URIs for a RIF-CS document" do
      doc = Nokogiri::XML(get_fixture('party', '1d'))
      subject.email_uris(doc).each do |uri|
        uri.should match(/^mailto:/)
      end
      addrs = subject.email_uris(doc).map {|addr| addr.gsub(/^mailto:/, '')}
      addrs.map{|addr| CGI.unescapeHTML(addr)}.should == \
        subject.email_addresses(doc)
    end
  end

  describe "description" do
    it "provides the first description for a RIF-CS document" do
      doc = Nokogiri::XML(get_fixture('party', '1d'))
      subject.description(doc).should == \
        'A software engineer working at the UQ ITEE e-Research Group.'
    end
  end

  describe "urls" do
    let(:doc) { Nokogiri::XML(get_fixture('party', '1d')) }

    it "produces a list of address URLs for a RIF-CS document" do
      subject.address_urls(doc).should be ==
        ["http://nla.gov.au/nla.party-1486629"]
    end

    it "produces a list of identifier URLs for a RIF-CS document" do
      subject.identifier_urls(doc).should be ==
        ["http://nla.gov.au/nla.party-1486629",
         "http://services.ands.org.au/home/orca/rda/view.php?"+
         "key=mirage.cmm.uq.edu.au/user/1"]
    end

    it "produces a list of all URLs for a RIF-CS document" do
      subject.urls(doc).count.should be == 2
      subject.urls(doc).to_set.should be == (
        subject.identifier_urls(doc) +
        subject.address_urls(doc)
      ).to_set
    end
  end

  describe "rights_data_from_url" do
    it "produces attributes from an RDF document" do
      VCR.use_cassette('cc_by_rdf') do
        data = rights_data_from_url(
          'http://creativecommons.org/licenses/by/3.0/rdf'
        )
        data.should have_key(:href)
        data.should have_key(:title)
        data[:title].should be == "Attribution 3.0 Unported"
        data.should have_key(:logo)
      end
    end

    it "produces attributes from HTML with an alternate RDF representation" do
      VCR.use_cassette('gpl_v3_html') do
        url = 'http://gnu.org/licenses/gpl-3.0.html'
        data = rights_data_from_url(url)
        data.should have_key(:href)
        # Note: this isn't *always* the case, due to 30x redirects
        data[:href].should be == url
        data.should have_key(:title)
        data[:title].should be == "GNU General Public License"
        data.should have_key(:logo)
      end
    end

    it "produces attributes from an HTML document" do
      VCR.use_cassette('mpl_html') do
        url = 'http://www.mozilla.org/MPL/'
        data = rights_data_from_url('http://www.mozilla.org/MPL/')
        data[:href].should be == url
        data[:title].should == 'Mozilla Public License'
      end
    end
  end

end
