require 'spec_helper'

describe Miletus::Harvest::Atom::RDC::Entry do

  def get_fixture(n)
    fixture_file = File.join(File.dirname(__FILE__),
        '..', '..', 'fixtures', 'atom-entry-%d.xml' % n)
    Miletus::Harvest::Atom::RDC::Entry.new(:xml => IO.read(fixture_file))
  end

  it { should respond_to(:xml, :to_rif) }

  it "should convert a dataset to RIF-CS" do
    subject = get_fixture(1)
    @doc = Nokogiri::XML(subject.to_rif)
    rifcs_schema = Miletus::NamespaceHelper::ns_by_prefix('rif').schema
    rifcs_schema.validate(@doc).should == []
    objects = @doc.xpath('//rif:registryObject', ns_decl)
    objects.count.should > 1
    objects.each do |obj|
      obj.at_xpath('rif:*/rif:name', ns_decl).should_not be_nil
    end
    primary_object = objects.first
    primary_object.xpath('rif:collection/rif:identifier',
      ns_decl).should_not be_nil
    primary_object.xpath('rif:collection/rif:subject', ns_decl).count.should \
      == 6
    primary_object.at_xpath('rif:collection/rif:rights/rif:accessRights',
      ns_decl).should_not be_nil
    primary_object.at_xpath('rif:collection/rif:rights/rif:licence',
      ns_decl).should_not be_nil
    primary_object.at_xpath('rif:collection/rif:rights/rif:rightsStatement',
      ns_decl).should_not be_nil
  end

  it "should convert an agent to RIF-CS" do
    subject = get_fixture(2)
    @doc = Nokogiri::XML(subject.to_rif)
    rifcs_schema = Miletus::NamespaceHelper::ns_by_prefix('rif').schema
    rifcs_schema.validate(@doc).should == []
    objects = @doc.xpath('//rif:registryObject', ns_decl)
    objects.count.should == 1
    primary_object = objects.first
    primary_object.xpath('rif:party/rif:identifier',
      ns_decl).should_not be_nil
    name = primary_object.at_xpath('rif:party/rif:name', ns_decl)
    name.should_not be_nil
    name.at_xpath('rif:namePart[@type="family"]', ns_decl).should_not be_nil
    name.at_xpath('rif:namePart[@type="given"]',  ns_decl).should_not be_nil
    primary_object.xpath('rif:party/rif:subject', ns_decl).count.should == 2
  end


end