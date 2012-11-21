require 'spec_helper'

require 'miletus/harvest/atom_entry_patch'

describe Atom::Entry do

  it { should respond_to(:metas, :rights) }

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
      obj.content.should be == \
        'This data is freely available via the DIMER website'
      obj.property.should == 'http://purl.org/dc/terms/accessRights'
    end

    it "should be registered in the element specs" do
      Atom::Entry.element_specs.should have_key('meta')
      parser = Atom::Entry.element_specs['meta']
      parser.name.should be == 'metas'
      parser.options[:class].should be == Atom::Entry::RdfaMeta
      parser.attribute.should be == :metas
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

  describe ":georss_polygons" do
    subject do
      fixture_file = File.join(File.dirname(__FILE__),
          '..', 'fixtures', 'atom-entry-3.xml')
      Atom::Entry.new(XML::Reader.string(IO.read(fixture_file)))
    end

    it "should provide property and content info" do
      subject.should respond_to(:georss_polygons)
      subject.should have(1).georss_polygons
      subject.georss_polygons.first.should \
        be_a_kind_of(GeoRuby::SimpleFeatures::Polygon)
      polygon = subject.georss_polygons.first
      polygon.rings.first.kml_poslist({}).split(' ').should be == %w[
        143.4947,-9.3985000000002
        154.9387,-24.4123
        155.3876,-30.5956
        149.4398,-45.5735
        145.3856,-45.5232
        130.4967,-34.4765
        117.4523,-37.3957
        113.5287,-34.4645
        112.4745,-21.3876
        129.4475,-10.3825
        143.4947,-9.3985000000002
      ]
    end
  end

  describe ":metas" do
    subject do
      fixture_file = File.join(File.dirname(__FILE__),
          '..', 'fixtures', 'atom-entry-1.xml')
      Atom::Entry.new(XML::Reader.string(IO.read(fixture_file)))
    end

    it "should provide property and content info" do
      subject.should respond_to(:metas)
      subject.should have(1).metas
    end
  end

end