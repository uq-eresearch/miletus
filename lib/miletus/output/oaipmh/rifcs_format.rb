require 'oai'

module Miletus
  module Output
    module OAIPMH

      class RifcsFormat < OAI::Provider::Metadata::Format
        def initialize
          @prefix = 'rif'
          @namespace = 'http://ands.org.au/standards/rif-cs/registryObjects'
          @schema = 'http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd'
          @element_namespace = 'rif'
          @fields = [ :registryObject ]
        end

        def header_specification
          {
            'xmlns:rif' => "http://ands.org.au/standards/rif-cs/registryObjects",
            'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
            'xsi:schemaLocation' =>
              %{http://ands.org.au/standards/rif-cs/registryObjects
                http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd}
          }
        end
      end

    end
  end
end