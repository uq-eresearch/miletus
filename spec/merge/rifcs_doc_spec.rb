require 'spec_helper'

describe Miletus::Merge::RifcsDocs do

  it { should respond_to(:content_from_nodes, :merge) }

  def read_fixture(fixture_file)
    filename = File.join( File.dirname(__FILE__), '..',
                          'fixtures', fixture_file)
    File.open(filename) do |f|
      f.read
    end
  end


  describe "missing descriptions" do

    it "should generate a description if missing" do
      include Miletus::NamespaceHelper
      # Strip out descriptions
      doc = Nokogiri::XML(read_fixture('rifcs-collection-1.xml'))
      doc.xpath('//rif:description', ns_decl).map(&:unlink)
      doc.xpath('//rif:description', ns_decl).should be_empty
      docs = described_class.new([doc.to_xml])
      doc = Nokogiri::XML(docs.merge.to_xml)
      doc.xpath('//rif:description', ns_decl).should_not be_empty
      doc.at_xpath('//rif:description/@type', ns_decl).to_s.should be == 'brief'
      doc.at_xpath('//rif:description', ns_decl).content.should be == ' '
    end

    it "should generate a description if only other description is empty" do
      include Miletus::NamespaceHelper
      # Strip out descriptions
      doc = Nokogiri::XML(read_fixture('rifcs-collection-1.xml')).tap do |d|
        desc_parent = d.at_xpath('//rif:description', ns_decl).parent
        d.xpath('//rif:description', ns_decl).map(&:unlink)
        Nokogiri::XML::Builder.with(desc_parent) do |xml|
          xml.description('', :type => 'full')
        end
      end
      doc.xpath('//rif:description', ns_decl).count.should be == 1
      docs = described_class.new([doc.to_xml])
      doc = Nokogiri::XML(docs.merge.to_xml)
      doc.xpath('//rif:description', ns_decl).should_not be_empty
      doc.at_xpath('//rif:description/@type', ns_decl).to_s.should be == 'brief'
      doc.at_xpath('//rif:description', ns_decl).content.should be == ' '
    end

  end

end

describe Miletus::Merge::RifcsDoc do

  it { should respond_to(:sort_key, :titles, :types, :group=, :key=) }

end
