require 'spec_helper'
require 'open-uri'
require 'webmock/rspec'
require 'yaml'

describe Miletus::Harvest::Document::RDCAtom do

  it { should respond_to(:to_rif) }

  it { should be_kind_of(Miletus::Harvest::Document::Base) }

  describe ":after_metadata_change event" do
    before(:each) do
      subject.url = 'http://dimer.uq.edu.au/dataspace.atom'
    end

    around(:each) do |example|
      VCR.use_cassette('dimer_remote_atom_rdc_feed_rdfa_mirror') do
        example.run
      end
    end

    it "should not trigger on save" do
      described_class.should_receive(:notify_observers) \
                     .with(:after_metadata_change, subject) \
                     .never
      subject.save!
    end

    it "should trigger after new data is fetched" do
      described_class.should_receive(:notify_observers) \
                     .with(:after_metadata_change, subject) \
                     .once
      subject.fetch
    end

    it "should trigger when URL is assigned" do
      described_class.should_receive(:notify_observers) \
                     .with(:after_metadata_change, subject) \
                     .once
      subject.url = 'http://dimer.uq.edu.au/dataspace.atom'
    end

    it "should trigger when document is cleared" do
      described_class.should_receive(:notify_observers) \
                     .with(:after_metadata_change, subject) \
                     .once
      subject.clear
    end
  end

  it "should produce valid RIF-CS" do
    subject.url = 'http://dimer.uq.edu.au/dataspace.atom'
    # Save, or we won't be able to have dependent entries
    subject.save!
    VCR.use_cassette('dimer_remote_atom_rdc_feed_rdfa_mirror') do
      subject.fetch
    end
    subject.document.should be_present
    subject.document.content_type.should be == 'application/xml'
    rifcs_doc = Nokogiri::XML(subject.to_rif)
    ns_by_prefix('rif').schema.valid?(rifcs_doc).should be_true
  end

  it "should handle UTF-8 multi-byte characters" do
    subject.url = 'http://dimer-uat.metadata.net/authors/bfd.atom'
    # Save, or we won't be able to have dependent entries
    subject.save!
    VCR.use_cassette('dimer_unicode_example') do
      subject.fetch
    end
    subject.document.should be_present
    subject.document.content_type.should be == 'application/xml'
    rifcs_doc = Nokogiri::XML(subject.to_rif)
    ns_by_prefix('rif').schema.valid?(rifcs_doc).should be_true
  end

end