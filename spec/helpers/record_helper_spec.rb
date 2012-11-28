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

  describe "keywords" do
    it "provides keywords for meta tag" do
      doc = Nokogiri::XML(get_fixture('activity', 1))
      subject.keywords(doc).should be == [
        '040303',
        '0402',
        '0403',
        '040203',
        'digital mapping',
        'digital map coordinates',
        'analytical results',
        'major oxides',
        'trace element analysis',
        'whole rock analysis',
        'specimen information',
        'stable isotypes',
        'dating techniques',
        'geochemistry analysis',
        'geographic locality'
      ]
    end
  end

  describe "subjects" do
    it "provides subjects for display" do
      doc = Nokogiri::XML(get_fixture('activity', 1))
      subjects = subject.subjects(doc)
      subjects.each do |s|
        s.should respond_to(:name)
        s.should respond_to(:type)
      end
      subjects.map(&:name).should be == [
        '040303',
        '0402',
        '0403',
        '040203',
        'digital mapping',
        'digital map coordinates',
        'analytical results',
        'major oxides',
        'trace element analysis',
        'whole rock analysis',
        'specimen information',
        'stable isotypes',
        'dating techniques',
        'geochemistry analysis',
        'geographic locality'
      ]
      grouped = subjects.group_by(&:type)
      grouped['ANZSRC FOR'].count.should be == 4
      grouped['LOCAL'].count.should be == (subjects.count - 4)
    end
  end

  describe "name" do
    it "produces a hash of name parts" do
      doc = Nokogiri::XML(get_fixture('party', '1'))
      subject.name(doc).should be == {
        'family' => %w[ Dettrick ],
        'given' => %w[ Timothy John ]
      }
    end
  end

  describe "urls" do
    let(:doc) { Nokogiri::XML(get_fixture('party', '1d')) }
    let(:other_doc) { Nokogiri::XML(get_fixture('party', 'fryer-library')) }

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

    it "should filter identifiers which are not URLs" do
      subject.identifier_urls(other_doc).should be ==
        ["http://www.library.uq.edu.au/fryer/"]
    end

  end

  describe "physical_addresses" do
    it "produces physical address information" do
      doc = Miletus::Merge::RifcsDoc.create(
        get_fixture('party', 'fryer-library'))
      physical_addresses = subject.physical_addresses(doc)
      physical_addresses.count.should be == 1
      physical_address = physical_addresses.first
      physical_address['addressLine'].should be == [
        'Level 4',
        'Duhig Building',
        'St Lucia Campus',
        'The University of Queensland, Q 4072'
      ]
      physical_address['telephoneNumber'] = '+ 61 (7) 3365 6276'
      physical_address['faxNumber'] = '+ 61 (7) 3365 6776'
    end
  end

  describe "rights" do
    it "produces rights information" do
      doc = Miletus::Merge::RifcsDoc.create(
        get_fixture('collection', '1b'))
      rights = subject.rights(doc)
      rights['accessRights'][:title].should be == %w[
        The data in this project is only available to users on the OzTrack
        system whom have been granted access. Contact the Collection Manager
        regarding permission and procedures for accessing the data.
      ].join(' ')
      rights['accessRights'].should_not have_key(:href)
      rights['rightsStatement'][:title].should be == %w[
        The data is the property of the University of Queensland. Permission is
        required to use this material.
      ].join(' ')
      rights['rightsStatement'].should_not have_key(:href)
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

  describe 'type_image' do
    context 'known types' do
      %w[activity collection party service].each do |type|
        it "provides an image tag for #{type.pluralize}" do
          html = type_image(type)
          html.should_not be == ''
          doc = Nokogiri::XML(html)
          doc.root.name.should be == 'img'
          doc.root.attributes.keys.to_set.should be == \
            %w[alt class src title].to_set
          doc.root['alt'].should be == type.titleize
          doc.root['title'].should be == doc.root['alt']
          doc.root['class'].should be == 'icon'
          doc.root['src'].length.should be > 0
        end
      end
    end
    context 'unknown type' do
      it 'returns an empty string' do
        type_image('foobar').should be == ''
      end
    end
  end

end
