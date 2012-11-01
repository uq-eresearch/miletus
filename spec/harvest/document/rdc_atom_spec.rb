require 'spec_helper'
require 'open-uri'
require 'webmock/rspec'
require 'yaml'

describe Miletus::Harvest::Document::RDCAtom do

  it { should respond_to(:url, :document, :fetch, :to_rif) }

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

end