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

  describe "title" do

    it "produces a list of titles for a RIF-CS document" do
      doc = Nokogiri::XML(get_fixture('party', 1))
      subject.titles(doc).should == ["Timothy John Dettrick", "Tim Dettrick"]
    end

    it "ignores duplicate items" do
      doc = Nokogiri::XML(get_fixture('party', '1d'))
      subject.titles(doc).should == ["Mr Timothy John Dettrick", "Tim Dettrick"]
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
    it "produces a list of URLs for a RIF-CS document" do
      doc = Nokogiri::XML(get_fixture('party', '1d'))
      subject.urls(doc).should == ["http://nla.gov.au/nla.party-1486629"]
    end
  end

end
