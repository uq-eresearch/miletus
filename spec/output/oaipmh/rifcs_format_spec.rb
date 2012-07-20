require 'uri'
require 'faraday'
require 'faraday_middleware'
require 'miletus/output/oaipmh/rifcs_format'

describe Miletus::Output::OAIPMH::RifcsFormat do

  describe "header specification" do

    subject {
      Miletus::Output::OAIPMH::RifcsFormat.instance.header_specification
    }

    it "should have a \"rif\" namespace prefix" do
      subject.has_key?('xmlns:rif').should be(true)
    end

    it "should have an ANDS namespace" do
      uri = URI.parse(subject['xmlns:rif'])
      uri.host.should == "ands.org.au"
    end

    it "should have valid schema locations" do
      # It should have have schema locations
      subject.has_key?('xsi:schemaLocation').should be(true)
      schemaLocations = subject['xsi:schemaLocation'].split(/\s+/)
      schemaLocations.count.should satisfy { |n| n > 0 and n.even? }
      # Check those schemas actually exist
      schemas = Hash[*schemaLocations]
      schemas.values.each do |url|
        client = Faraday.new(:url => url) do |faraday|
          faraday.response :follow_redirects
          faraday.adapter  Faraday.default_adapter
        end
        response = client.head
        response.success?.should be(true)
      end
    end

  end

end