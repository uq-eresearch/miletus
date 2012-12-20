require 'factory_girl'

FactoryGirl.define do

  class OaiRecord < Struct.new(:header, :metadata); end
  class OaiHeader < Struct.new(:identifier, :datestamp, :status)
    def deleted?
      status == 'deleted'
    end
  end

  factory :oai_record do
    association :header, factory: :oai_header, strategy: :build
    metadata { LibXML::XML::Node.new('metadata') }
  end

  factory :oai_header do
    ignore do
      deleted false
    end
    sequence(:identifier) {|n| "http://example.test/#{n}" }
    datestamp { DateTime.now }
    status { deleted ? 'deleted' : '' }
  end
end