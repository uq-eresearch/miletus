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
        link.document.to_rif.should_not be_nil
      end
      Miletus::Merge::Concept.all.each do |c|
        puts c.to_rif
      end
      Miletus::Merge::Concept.count.should be == 3
    end
  end

end
