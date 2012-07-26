module Miletus::Output::OAIPMH

  class RifcsFormat < OAI::Provider::Metadata::Format
    def initialize
      @prefix = 'rif'
      @namespace = 'http://ands.org.au/standards/rif-cs/registryObjects'
      @schema = 'http://services.ands.org.au' +
        '/documentation/rifcs/schema/registryObjects.xsd'
      @element_namespace = 'rif'
      @fields = [ :registryObject ]
    end

    def header_specification
      {
        'xmlns:rif' => @namespace,
        'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
        'xsi:schemaLocation' =>
          %{#{@namespace}
            #{@schema}}
      }
    end
  end

end