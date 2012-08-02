require 'spec_helper'
require 'time'
require 'miletus'

describe Miletus::Merge::Concept do

  let(:ns_decl) do
    Miletus::NamespaceHelper::ns_decl
  end

  def get_fixture(type, number = 1)
    fixture_file = File.join(File.dirname(__FILE__),
        '..', 'fixtures',"rifcs-#{type}-#{number}.xml")
    File.open(fixture_file) { |f| f.read() }
  end

  def get_identifiers(rifcs)
    Nokogiri::XML(rifcs).xpath('//rif:identifier', ns_decl).map do |e|
      e.content.strip
    end
  end

  it { should respond_to(:facets) }

  it "should merge facet metadata when identifiers match" do
    # Create multi-faceted concept
    concept = Miletus::Merge::Concept.create()
    [1, '1b'].map {|n| get_fixture('party', n) }.each do |fixture_xml|
      concept.facets.create(:metadata => fixture_xml)
    end
    concept.should have(2).facets
    concept.to_rif.should_not be(nil)
    merged_identifiers = get_identifiers(concept.to_rif).to_set
    concept.facets.each do |f|
      get_identifiers(f.to_rif).to_set.should be_subset(merged_identifiers)
    end
    merged_doc = Nokogiri::XML(concept.to_rif)
    merged_doc.xpath('//rif:location', ns_decl).count.should == 2
    merged_doc.xpath('//rif:name', ns_decl).count.should == 2
  end

  it "should index identifiers" do
    fixture_metadata = get_fixture('party')
    concept = Miletus::Merge::Concept.create()
    concept.facets.create(:metadata => fixture_metadata)
    # Update
    concept.update_indexed_attributes_from_facet_rifcs
    # Indexed attributes should be created
    concept.indexed_attributes.where(:key => 'identifier').count.should ==
      get_identifiers(fixture_metadata).count
  end

  it "should index related object keys" do
    fixture_metadata = get_fixture('collection')
    concept = Miletus::Merge::Concept.create()
    concept.facets.create(:metadata => fixture_metadata)
    # Update
    concept.update_indexed_attributes_from_facet_rifcs
    # Indexed attributes should be created
    concept.indexed_attributes.where(:key => 'relatedKey').count.should == 1
  end

  it "should find related concepts using keys" do
    [get_fixture('collection', 1), get_fixture('party', 1)].each do |xml|
      concept = Miletus::Merge::Concept.create()
      k = Nokogiri::XML(xml).at_xpath('//rif:registryObject/rif:key', ns_decl)\
        .content.strip
      concept.facets.create(:key => k, :metadata => xml)
      # Update
      concept.update_indexed_attributes_from_facet_rifcs
    end
    Miletus::Merge::Concept.count.should == 2
    Miletus::Merge::Concept.all.each do |concept|
      concept.related_concepts.count.should == 1
    end
  end

end
