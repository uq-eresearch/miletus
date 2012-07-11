require 'bundler/setup'
require 'clockwork'
require 'delayed_job_active_record'

require 'oai-relay/consumer'
require 'oai-relay/record_collection'

Clockwork.every(5.minutes, 'check.upstreams') do
  RecordCollection.find_each do |rc|
    puts "Creating update job for #{rc}"
    Delayed::Job.enqueue Consumer.new(rc)
  end
end
