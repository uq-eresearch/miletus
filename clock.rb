require 'bundler/setup'
require 'clockwork'
require 'delayed_job_active_record'
require 'miletus'

module Clockwork
  every(5.minutes, 'check.upstreams') do
    jobs = Miletus::Harvest::OAIPMH::RIFCS.jobs
    if jobs.length > 0
      jobs.each do |job|
        puts "Scheduling harvest job for #{job}"
        Delayed::Job.enqueue job
      end
    else
      puts "No harvest jobs to schedule."
    end
  end
end
