require 'bundler/setup'
require 'clockwork'
require 'delayed_job_active_record'

Clockwork.every(5.minutes, 'check.upstreams') do
  include

  Miletus::Harvest::OAIPMH::RIFCS.jobs.each do |job|
    puts "Scheduling harvest job for #{job}"
    Delayed::Job.enqueue job
  end
end
