require 'spec_helper'
require 'time'

describe Miletus::Merge::Concept do

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

  it { should respond_to(:facets, :indexed_attributes, :key) }

  it "should merge facet metadata when identifiers match" do
    # Create multi-faceted concept
    concept = Miletus::Merge::Concept.create()
    [1, '1b'].map{|n| get_fixture('party', n)}.each do |fixture_xml|
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
    merged_doc.xpath('//rif:name[@type="primary"]', ns_decl).count.should == 1
  end

  it "should deduplicate primary names from facet metadata" do
    # Create multi-faceted concept
    concept = Miletus::Merge::Concept.create()
    [1, '1d'].map{|n| get_fixture('party', n)}.each do |fixture_xml|
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
    merged_doc.xpath('//rif:name', ns_decl).count.should == 4
    merged_doc.xpath('//rif:name[@type="primary"]', ns_decl).count.should == 1
    # Primary name should be the "best" one we have, not the first
    merged_doc.xpath('//rif:name[@type="primary"]/rif:namePart[@type="given"]',
      ns_decl).count.should == 2
  end


  it "should merge facet metadata with some missing elements" do
    # Create multi-faceted concept
    ['1b', '1c'].permutation.each do |permutation|
      concept = Miletus::Merge::Concept.create()
      permutation.map {|n| get_fixture('party', n) }.each do |fixture_xml|
        concept.facets.create(:metadata => fixture_xml)
      end
      concept.should have(2).facets
      concept.to_rif.should_not be(nil)
      merged_identifiers = get_identifiers(concept.to_rif).to_set
      concept.facets.each do |f|
        get_identifiers(f.to_rif).to_set.should be_subset(merged_identifiers)
      end
      merged_doc = Nokogiri::XML(concept.to_rif)
      merged_doc.xpath('//rif:location', ns_decl).count.should == 1
      merged_doc.xpath('//rif:name', ns_decl).count.should == 1
      ns_by_prefix('rif').schema.valid?(merged_doc).should be_true
      concept.destroy
    end
  end

  describe "RIF-CS group replacement" do

    def create_concept_for_group_replacement
      # Create multi-faceted concept
      concept = Miletus::Merge::Concept.create()
      [1, '1b'].map {|n| get_fixture('party', n) }.each do |fixture_xml|
        concept.facets.create(:metadata => fixture_xml)
      end
      concept.should have(2).facets
      concept.to_rif.should_not be(nil)
      concept
    end

    it "should replace existing RIF-CS group with its own" do
      concept = create_concept_for_group_replacement
      merged_doc = Nokogiri::XML(concept.to_rif)
      key_e = merged_doc.at_xpath('//rif:registryObject/@group', ns_decl)
      key_e.content.strip.should == concept.group
    end

    it "should use ENV['CONCEPT_GROUP'] as the group name if available" do
      concept = create_concept_for_group_replacement
      group_name = 'The University of Queensland'
      begin
        ENV['CONCEPT_GROUP'] = group_name
        concept.group.should == group_name
      ensure
        ENV.delete('CONCEPT_GROUP')
      end
    end

  end

  describe "RIF-CS key replacement" do

    def create_concept_for_key_replacement
      # Create multi-faceted concept
      concept = Miletus::Merge::Concept.create()
      [1, '1b'].map {|n| get_fixture('party', n) }.each do |fixture_xml|
        concept.facets.create(:metadata => fixture_xml)
      end
      concept.should have(2).facets
      concept.to_rif.should_not be(nil)
      concept
    end

    it "should replace existing RIF-CS key with its own" do
      concept = create_concept_for_key_replacement
      merged_doc = Nokogiri::XML(concept.to_rif)
      key_e = merged_doc.at_xpath('//rif:registryObject/rif:key', ns_decl)
      key_e.content.strip.should == concept.key
    end

    it "should use ENV['CONCEPT_KEY_PREFIX'] as the key prefix if available" do
      concept = create_concept_for_key_replacement
      prefix = 'http://example.test/prefix/'
      begin
        ENV['CONCEPT_KEY_PREFIX'] = prefix
        concept.key.should match(/^#{Regexp.escape(prefix)}/)
      ensure
        ENV.delete('CONCEPT_KEY_PREFIX')
      end
    end
  end

  it "should index identifiers" do
    fixture_metadata = get_fixture('party')
    concept = Miletus::Merge::Concept.create()
    concept.facets.create(:metadata => fixture_metadata)
    # Indexed attributes should be created
    concept.indexed_attributes.where(:key => 'identifier').count.should ==
      get_identifiers(fixture_metadata).count
  end

  it "should index related object keys" do
    fixture_metadata = get_fixture('collection')
    concept = Miletus::Merge::Concept.create()
    concept.facets.create(:metadata => fixture_metadata)
    # Indexed attributes should be created
    concept.indexed_attributes.where(:key => 'relatedKey').count.should == 1
  end

  it "should find related concepts using keys and map them in RIF-CS" do
    [get_fixture('collection', 1), get_fixture('party', 1)].each do |xml|
      concept = Miletus::Merge::Concept.create()
      concept.facets.create(:metadata => xml)
    end
    Miletus::Merge::Concept.count.should == 2
    Miletus::Merge::Concept.all.each do |concept|
      concept.related_concepts.count.should == 1
      doc = Nokogiri::XML(concept.to_rif)
      doc.xpath('//rif:relatedObject/rif:key', ns_decl).each do |other_key_e|
        other_key_e.content.strip.should == concept.related_concepts.first.key
      end
    end
  end

  describe "GEXF generation" do

    describe "global GEXF graph" do

      before(:each) do
        # Create some data
        %w[party collection].map{|t| get_fixture(t, 1)}.each do |fixture_xml|
          concept = Miletus::Merge::Concept.create()
          concept.facets.create(:metadata => fixture_xml)
        end
      end

      let(:doc) { Nokogiri::XML(subject.class.to_gexf) }

      it "should generate a valid global GEXF graph" do
        ns_by_prefix('gexf').schema.validate(doc).should == []
      end

      it "should have a node for each concepts" do
        doc.xpath('//gexf:node', ns_decl).count.should == subject.class.count
      end

      it "should have a label for each node" do
        doc.xpath('//gexf:node/@label',
          ns_decl).count.should == subject.class.count
      end

      it "should have an edge for each relationship for each concept" do
        relationship_count = Miletus::Merge::IndexedAttribute.where(
          :key => 'relatedKey'
        ).count
        edges = doc.xpath('//gexf:edge', ns_decl)
        edges.count.should == relationship_count
        edges.each do |e|
          ['source', 'target'].each do |a|
            lambda do
              Miletus::Merge::Concept.find_by_key!(e[a])
            end.should_not raise_error
          end
        end
      end

    end

  end

end
