require 'delayed_job'

Delayed::Worker.destroy_failed_jobs = false