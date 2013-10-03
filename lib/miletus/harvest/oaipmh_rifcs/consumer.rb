module Miletus
  module Harvest
    module OAIPMH
      module RIFCS

        class Consumer

          # Take endpoint to use and collection to update
          def initialize(recordCollection, client = nil)
            is_client = [:get_record, :list_identifiers].all? do |method|
              client.respond_to?(method)
            end

            is_collection = [:get, :add, :remove, :format].all? do |method|
              recordCollection.respond_to?(method)
            end

            unless is_collection
              raise ArgumentError.new(
                "Consumer requires a collection to update.")
            end

            @collection = recordCollection
            @client = client
          end

          def client
            @client or OAI::Client.new(@collection.endpoint,
                                       :parser => 'libxml')
          end

          # Update collection with changed records
          def update
            @collection.restrict_to do
              list_identifiers.select { |header|
                existing = @collection.get(header.identifier)
                (existing.nil? or existing.header.datestamp < header.datestamp)
              }.each { |header|
                if header.deleted?
                  remove_record(header)
                else
                  add_record(header)
                end
              }
            end
          end

          def perform
            puts "Checking for updates on #{@collection.to_s}"
            update
          end

          private

          def list_identifiers
            opts = { :metadataPrefix => @collection.format }
            opts[:set] = @collection.set unless @collection.set.nil?
            client.list_identifiers(opts).full
          end

          def add_record(header)
            record = client.get_record(
                :identifier => header.identifier,
                :metadataPrefix => @collection.format).record
            @collection.add(record)
          end

          def remove_record(header)
            @collection.remove(header.identifier, header.datestamp)
          end

        end

      end
    end
  end
end