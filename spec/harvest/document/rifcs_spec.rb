require 'spec_helper'
require 'open-uri'
require 'webmock/rspec'
require 'yaml'

describe Miletus::Harvest::Document::RIFCS do

  it { should respond_to(:to_rif, :to_rif_file) }

  it { should be_kind_of(Miletus::Harvest::Document::Base) }

  it "should work for the file scheme" do
    fixture_file = File.expand_path(
      File.join(File.dirname(__FILE__),
        '..', '..', 'fixtures', 'rifcs-activity-1.xml'))
    subject.url = 'file://%s' % fixture_file
    subject.save!
    subject.fetch
    subject.document.should be_present
    subject.to_rif.should be == File.read(fixture_file)
    subject.document.content_type.should == 'application/xml'
  end

  it "should work for HTTP" do
    VCR.use_cassette('ands_rifcs_example') do
      subject.url = \
        'http://services.ands.org.au/documentation/rifcs/example/rif.xml'
      subject.save!
      subject.fetch
    end
    subject.document.should be_present
    VCR.use_cassette('ands_rifcs_example') do
      subject.to_rif.should be == open(subject.url).read
      subject.document.content_type.should == 'application/xml'
    end
  end

  it "should work for gzipped representations" do
    VCR.use_cassette('uq_rifcs_example') do
      subject.url = \
        'http://uq-eresearch.github.com/rifcs-examples/'+
        'the_university_of_queensland.rifcs.xml'
      subject.save!
      subject.fetch
    end
    subject.document.should be_present
    VCR.use_cassette('uq_rifcs_example') do
      subject.to_rif.should be == Zlib::GzipReader.new(open(subject.url)).read
      subject.document.content_type.should == 'application/xml'
    end
  end

  it "should take advantage of Etag and Last-Modified headers" do
    VCR.use_cassette('ands_rifcs_example') do
      subject.url = \
        'http://services.ands.org.au/documentation/rifcs/example/rif.xml'
      subject.save!
      subject.fetch
      WebMock.should have_requested(:get, subject.url).with(:headers => {
          'Accept' => '*/*',
          'User-Agent' => 'Ruby'
        })
    end
    subject.document.should be_present
    VCR.use_cassette('ands_rifcs_example_304') do
      subject.url = \
        'http://services.ands.org.au/documentation/rifcs/example/rif.xml'
      subject.save!
      subject.fetch
      WebMock.should have_requested(:get, subject.url).with(:headers => {
          'Accept' => '*/*',
          'If-None-Match' => '"41b1ee-193b-4b1ce1cf46280"',
          'If-Modified-Since' => 'Tue, 15 Nov 2011 23:11:54 GMT',
          'User-Agent' => 'Ruby'
        })
    end
  end

  it "should clear the document when the URL changes" do
    fixture_file = File.expand_path(
      File.join(File.dirname(__FILE__),
        '..', '..', 'fixtures', 'rifcs-activity-1.xml'))
    subject.url = 'file://%s' % fixture_file
    subject.save!
    subject.fetch
    subject.document.should be_present
    subject.to_rif.should be == File.read(fixture_file)
    subject.url = fixture_file.gsub(/1\.xml$/, '2.xml')
    subject.document.should_not be_present
  end

end