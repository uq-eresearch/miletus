require 'spec_helper'

describe Miletus::Harvest::Atom::RDC::Feed do

  it { should respond_to(:url, :entries) }

  it "should provide an remote entry iterator which handles paging" do
    subject.should respond_to(:remote_entries)
    # Test with a feed that uses 20 entry pages
    subject.url = 'http://dataspace.uq.edu.au/collections.atom'
    VCR.use_cassette('dataspace_remote_atom_rdc_feed') do
      subject.remote_entries.count.should == 42
    end
  end

  it "should be able to mirror remote entries" do
    subject.should respond_to(:mirror)
    subject.url = 'http://dataspace.uq.edu.au/collections.atom'
    # Save, or we won't be able to have dependent entries
    subject.save!
    VCR.use_cassette('dataspace_remote_atom_rdc_feed') do
      subject.mirror
      subject.entries.count == 42
    end
  end

end