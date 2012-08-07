module Miletus::Output::OAIPMH

  class RifcsFormat < OAI::Provider::Metadata::Format
    def initialize
      @prefix = 'rif'
      ns_obj = Miletus::NamespaceHelper::ns_by_prefix(@prefix)
      @namespace = ns_obj.uri
      @schema = ns_obj.schema_location
      @element_namespace = @prefix
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