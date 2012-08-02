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

  it { should respond_to(:facets) }

  it "should merge facet metadata when identifiers match" do
    def get_identifiers(rifcs)
      Nokogiri::XML(rifcs).xpath('//rif:identifier', ns_decl).map do |e|
        e.content.strip
      end
    end
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

end
