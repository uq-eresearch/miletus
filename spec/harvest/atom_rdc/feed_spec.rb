require 'spec_helper'

describe Miletus::Harvest::Atom::RDC::Feed do

  it { should respond_to(:url, :entries) }

  it "should provide an remote entry iterator which handles paging" do
    subject.should respond_to(:remote_entries)
    # Test with a feed that uses 20 entry pages
    subject.url = 'http://dataspace.uq.edu.au/collections.atom'
    VCR.use_cassette('dataspace_remote_atom_rdc_feed_remote_entries') do
      subject.remote_entries.count.should == 42
    end
  end

  it "should be able to mirror remote entries" do
    subject.should respond_to(:mirror)
    subject.url = 'http://dataspace.uq.edu.au/collections.atom'
    # Save, or we won't be able to have dependent entries
    subject.save!
    VCR.use_cassette('dataspace_remote_atom_rdc_feed_mirror') do
      subject.mirror
      subject.entries.count == 42
      subject.remote_entries.each do |remote_entry|
        local_entry = subject.entries.find_by_atom_id(remote_entry.id)
        local_entry.should_not be_nil
        local_entry.title.should == remote_entry.title
        local_entry.updated.iso8601.should == remote_entry.updated.iso8601
      end
    end
  end

  it "should mirror rdfa:meta elements" do
    subject.should respond_to(:mirror)
    subject.url = 'http://dimer.uq.edu.au/dataspace.atom'
    # Save, or we won't be able to have dependent entries
    subject.save!
    VCR.use_cassette('dimer_remote_atom_rdc_feed_rdfa_mirror') do
      subject.mirror
      subject.remote_entries.each do |remote_entry|
        local_entry = subject.entries.find_by_atom_id(remote_entry.id)
        local_entry.should_not be_nil
        remote_entry.should respond_to(:metas)
        local_entry.should respond_to(:metas)
        local_entry.metas.should == remote_entry.metas
      end
    end
  end

  it "should be able to mirror the same data multiple times" do
    subject.should respond_to(:mirror)
    updates = []
    %w[a b].each do |i|
      fixture_file = File.join(File.dirname(__FILE__),
          '..', '..', 'fixtures', 'atom-feed-test-1%s.xml' % i)
      subject.url = 'file://' + fixture_file
      subject.save!
      subject.mirror
      subject.reload.entries.count.should == 2
      subject.reload.entries.each {|e| updates << e.updated }
    end
    updates.uniq.count.should == 3
  end

end