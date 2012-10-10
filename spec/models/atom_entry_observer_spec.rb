require 'spec_helper'

describe AtomEntryObserver do

  subject { AtomEntryObserver.instance }

  it { should respond_to(:after_create, :after_update) }

  def get_fixture(n)
    fixture_file = File.join(File.dirname(__FILE__),
        '..', 'fixtures', 'atom-entry-%d.xml' % n)
    Miletus::Harvest::Atom::RDC::Entry.new(:xml => IO.read(fixture_file))
  end

  it "should create new concepts for a new harvested entry" do
    # Disable delayed run for hooks
    AtomEntryObserver.stub(:run_job).and_return { |j| j.run }
    # Check the database has no existing concepts
    Miletus::Merge::Concept.count.should == 0
    # Create entry
    entry = get_fixture(1)
    entry.save!
    # Check that associated concepts have been created
    Miletus::Merge::Concept.count.should == 6
  end

  it "should update concepts for an updated entry" do
    extend Miletus::NamespaceHelper
    # Disable delayed run for hooks
    AtomEntryObserver.stub(:run_job).and_return { |j| j.run }
    # Check the database has no existing concepts
    Miletus::Merge::Concept.count.should == 0
    # Create entry
    entry = get_fixture(1)
    entry.save!
    # Check that associated concepts have been created
    Miletus::Merge::Concept.count.should == 6
    updated_entry = entry.atom_entry
    updated_entry.content = "Test description"
    entry.xml = updated_entry.to_xml
    entry.save!
    collection = Miletus::Merge::IndexedAttribute.find_by_key_and_value(
      'identifier', 'http://dimer.uq.edu.au/ref/3r').concept
    doc = Miletus::Merge::RifcsDoc.parse(collection.to_rif)
    doc.at_xpath('//rif:description', ns_decl)\
      .content.should == 'Test description'
    # Check that associated concepts have been created
    Miletus::Merge::Concept.count.should == 6
  end

end
