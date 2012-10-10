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
    collection, *related_objects = objects
    collection.xpath('rif:collection/rif:identifier',
      ns_decl).should_not be_nil
    collection.at_xpath('rif:collection/rif:name',
      ns_decl).should_not be_nil
    collection.xpath('rif:collection/rif:subject', ns_decl).count.should \
      == 6
    collection.at_xpath('rif:collection/rif:rights/rif:accessRights',
      ns_decl).should_not be_nil
    collection.at_xpath('rif:collection/rif:rights/rif:licence',
      ns_decl).should_not be_nil
    collection.at_xpath('rif:collection/rif:rights/rif:rightsStatement',
      ns_decl).should_not be_nil
    collection.at_xpath('rif:collection/rif:relatedInfo',
      ns_decl).should_not be_nil
    collection.at_xpath('rif:collection/rif:relatedInfo',
      ns_decl).should_not be_nil
    # Collections
    related_objects.select do |ro|
      ro.at_xpath('rif:collection', ns_decl)
    end.tap do |collections|
      collections.count.should == 1
    end.each do |oc|
      oc.at_xpath('rif:collection/rif:identifier', ns_decl).should_not be_nil
      oc.at_xpath('rif:collection/rif:name', ns_decl).should_not be_nil
      # Author objects should have keys based on their parent
      oc.at_xpath('rif:key', ns_decl).content.start_with?(
        collection.at_xpath('rif:key', ns_decl).content)
      oc.at_xpath('rif:collection/rif:relatedObject',
        ns_decl).should_not be_nil
      # Author objects should related back to their collection
      oc.at_xpath('rif:collection/rif:relatedObject/rif:key', ns_decl)\
        .content.should == collection.at_xpath('rif:key', ns_decl).content
    end
    # Activities
    related_objects.select do |ro|
      ro.at_xpath('rif:activity', ns_decl)
    end.tap do |activities|
      activities.count.should == 1
    end.each do |activity|
      activity.at_xpath('rif:activity/rif:identifier', ns_decl).should_not\
        be_nil
      # Author objects should have keys based on their parent
      activity.at_xpath('rif:key', ns_decl).content.start_with?(
        collection.at_xpath('rif:key', ns_decl).content)
      activity.at_xpath('rif:activity/rif:relatedObject',
        ns_decl).should_not be_nil
      # Author objects should related back to their collection
      activity.at_xpath('rif:activity/rif:relatedObject/rif:key', ns_decl)\
        .content.should == collection.at_xpath('rif:key', ns_decl).content
    end
    # Parties
    related_objects.select do |ro|
      ro.at_xpath('rif:party', ns_decl)
    end.tap do |authors|
      authors.count.should == 3
    end.each do |author|
      author.at_xpath('rif:party/rif:identifier', ns_decl).should_not be_nil
      author.at_xpath('rif:party/rif:name', ns_decl).should_not be_nil
      # Author objects should have keys based on their parent
      author.at_xpath('rif:key', ns_decl).content.start_with?(
        collection.at_xpath('rif:key', ns_decl).content)
      author.at_xpath('rif:party/rif:relatedObject',
        ns_decl).should_not be_nil
      # Author objects should related back to their collection
      author.at_xpath('rif:party/rif:relatedObject/rif:key', ns_decl)\
        .content.should == collection.at_xpath('rif:key', ns_decl).content
    end
  end

  it "should convert an agent to RIF-CS" do
    subject = get_fixture(2)
    @doc = Nokogiri::XML(subject.to_rif)
    #puts @doc.to_xml
    rifcs_schema = Miletus::NamespaceHelper::ns_by_prefix('rif').schema
    rifcs_schema.validate(@doc).should == []
    objects = @doc.xpath('//rif:registryObject', ns_decl)
    objects.count.should == 2
    primary_object, *related_objects = objects
    primary_object.xpath('rif:party/rif:identifier',
      ns_decl).should_not be_nil
    name = primary_object.at_xpath('rif:party/rif:name', ns_decl)
    name.should_not be_nil
    name.at_xpath('rif:namePart[@type="family"]', ns_decl).should_not be_nil
    name.at_xpath('rif:namePart[@type="given"]',  ns_decl).should_not be_nil
    primary_object.xpath('rif:party/rif:subject', ns_decl).count.should == 2
    primary_object.xpath(
      'rif:party/rif:location/rif:address/rif:electronic[@type="email"]',
       ns_decl).count.should == 1
    primary_object.xpath(
      'rif:party/rif:location/rif:address/rif:electronic[@type="url"]',
       ns_decl).count.should == 1
    related_objects.select do |ro|
      ro.at_xpath('rif:collection', ns_decl)
    end.tap do |collections|
      collections.count.should == 1
    end.each do |collection|
      collection.at_xpath('rif:collection/rif:identifier', ns_decl)\
        .should_not be_nil
      collection.at_xpath('rif:collection/rif:name', ns_decl).should_not be_nil
      # Author objects should have keys based on their parent
      collection.at_xpath('rif:key', ns_decl).content.start_with?(
        collection.at_xpath('rif:key', ns_decl).content)
      collection.at_xpath('rif:collection/rif:relatedObject',
        ns_decl).should_not be_nil
      # Author objects should related back to their collection
      collection.at_xpath('rif:collection/rif:relatedObject/rif:key', ns_decl)\
        .content.should == primary_object.at_xpath('rif:key', ns_decl).content
    end
  end


end