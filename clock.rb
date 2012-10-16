require 'bundler/setup'
require 'clockwork'
require 'delayed_job_active_record'

module Clockwork
  every(5.minutes, 'check.upstreams') do
    require 'miletus'
    jobs = Miletus::Harvest::OAIPMH::RIFCS.jobs +
           Miletus::Harvest::Atom::RDC.jobs
    if jobs.length > 0
      jobs.each do |job|
        puts "Scheduling harvest job for #{job}"
        Delayed::Job.enqueue job
      end
    else
      puts "No harvest jobs to schedule."
    end
  end
  #every(1.day, 'recheck.sru') do
  #  Miletus::Merge::Concept.all.each do |concept|
  #    SruRifcsLookupObserver.instance.find_sru_records(concept)
  #  end
  #end
end
