require 'spec_helper'

require 'miletus/harvest/atom_rdc/atom_entry_patch'

describe Atom::Entry do

  it { should respond_to(:metas, :rights) }

  subject do
    fixture_file = File.join(File.dirname(__FILE__),
        '..', '..', 'fixtures', 'atom-entry-1.xml')
    Atom::Entry.new(XML::Reader.string(IO.read(fixture_file)))
  end

  describe "RdfaMeta" do
    it "should parse RDFA meta tags" do
      xml = <<-EOH
        <meta xmlns=\"http://www.w3.org/ns/rdfa#\"
          property=\"http://purl.org/dc/terms/accessRights\"
          content=\"This data is freely available via the DIMER website\"/>
      EOH
      reader = XML::Reader.string(xml)
      reader.read
      reader.read_outer_xml.should_not be_nil
      obj = Atom::Entry::RdfaMeta.new(reader)
      obj.content.should == \
        'This data is freely available via the DIMER website'
      obj.property.should == 'http://purl.org/dc/terms/accessRights'
    end

    it "should be registered in the element specs" do
      Atom::Entry.element_specs.should have_key('meta')
      parser = Atom::Entry.element_specs['meta']
      parser.name.should == 'metas'
      parser.options[:class].should == Atom::Entry::RdfaMeta
      parser.attribute.should == :metas
      xml = <<-EOH
        <rdfa:meta xmlns:rdfa=\"http://www.w3.org/ns/rdfa#\"
          property=\"http://purl.org/dc/terms/accessRights\"
          content=\"This data is freely available via the DIMER website\"/>
      EOH
      reader = XML::Reader.string(xml)
      reader.read
      mockEntry = Struct.new(:metas).new([])
      parser.parse(mockEntry, reader)
      mockEntry.metas.should have(1).meta
      mockEntry.metas.first.property.should_not be_nil
      mockEntry.metas.first.content.should_not be_nil
    end
  end

  describe ":rdfa_metas" do
    it "should provide property and content info" do
      subject.should respond_to(:metas)
      subject.should have(1).metas
    end
  end

end