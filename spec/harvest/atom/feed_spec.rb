require 'spec_helper'

describe Miletus::Harvest::Atom::Feed do

  it { should respond_to(:mirror, :remote_entries) }

  before(:each) do
    Delayed::Worker.delay_jobs = false
  end

  it "should be able to mirror data as documents" do
    VCR.use_cassette 'dataspace_rdcatom_feed_entries' do
      fixture_file = File.join(File.dirname(__FILE__),
          '..', '..', 'fixtures', 'atom-feed-test-1a.xml')
      subject.url = 'file://' + fixture_file
      subject.save!
      subject.mirror
      subject.reload
      subject.entries.count.should be == 3
      subject.entries.each do |e|
        e.should have(1).document_links
        link = e.document_links.first
        link.type.should be == 'application/atom+xml'
        atom_link = e.links.alternates.first
        link.document.url.should be == atom_link.href
        link.document.document.should be_present
        link.document.should be_managed
        link.document.to_rif.should_not be_nil
      end
      Miletus::Merge::Concept.count.should be == 3
    end
  end

  describe "normal feeds" do

    def fixture_filename(suffix)
      fixture_file = File.join(File.dirname(__FILE__),
          '..', '..', 'fixtures', 'atom-feed-test-%s.xml' % suffix)
    end


    it "should not remove entries not seen in subsequent passes" do
      VCR.use_cassette 'dataspace_rdcatom_feed_entries_normal_feed' do
        subject.url = 'file://' + fixture_filename('1a')
        subject.save!
        subject.mirror
        subject.reload
        subject.entries.count.should be == 3
        Miletus::Merge::Concept.count.should be == 3
        # Parse again, seeing one less entry
        subject.url = 'file://' + fixture_filename('1b')
        subject.save!
        subject.mirror
        subject.reload
        subject.entries.count.should be == 3
      end
    end

  end

  describe "complete feeds" do

    def fixture_filename(suffix)
      fixture_file = File.join(File.dirname(__FILE__),
          '..', '..', 'fixtures', 'atom-feed-test-complete-%s.xml' % suffix)
    end

    it "should remove entries not seen in subsequent passes" do
      VCR.use_cassette 'dataspace_rdcatom_feed_entries_complete_feed' do
        subject.url = 'file://' + fixture_filename('1a')
        subject.save!
        subject.mirror
        subject.reload
        subject.entries.count.should be == 3
        Miletus::Merge::Concept.count.should be == 3
        # Parse again, seeing one less entry
        subject.url = 'file://' + fixture_filename('1b')
        subject.save!
        subject.mirror
        subject.reload
        subject.entries.count.should be == 2
      end
    end

  end

  describe "out-of-order feeds" do

    def fixture_filename(suffix)
      fixture_file = File.join(File.dirname(__FILE__),
          '..', '..', 'fixtures', 'atom-feed-test-complete-%s.xml' % suffix)
    end

    it "should handle out-of-order entries in a single feed document" do
      VCR.use_cassette(
        'dataspace_rdcatom_feed_entries_out_of_order complete_feed'
      ) do
        subject.url = 'file://' + fixture_filename('2')
        subject.save!
        subject.mirror
        subject.reload
        subject.entries.count.should be == 3
        subject.entries.each do |entry|
          # Note: This is the entry update time we're checking
          entry.updated.iso8601.should be == '2012-09-05T16:13:26+10:00'
        end
      end
    end
  end



end
