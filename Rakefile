# Required for Bundler
require 'bundler/setup'

# Import Rake task for RSpec
require 'rspec/core/rake_task'
# Import DelayedJob tasks
require 'delayed_job_active_record'
require 'delayed/tasks'
# Add lib/ to path
$:.unshift File.join(File.dirname(__FILE__), 'lib')

desc "Run specs"
RSpec::Core::RakeTask.new()

desc "Run clockwork scheduler"
task :clock => :environment do |t|
  require File.join(File.dirname(__FILE__), 'clock')
  Clockwork.run
end

desc "Run console"
task :console => :environment do |t|
  require 'pry'
  pry
end

task :environment do |t|
  Delayed::Worker.destroy_failed_jobs = false
  STDOUT.sync = true
  require 'active_record'
  ActiveRecord::Base.establish_connection(
    ENV['DATABASE_URL']
  )
  ActiveRecord::Migrator.up "db/migrate"
  require 'oai-relay/consumer'
  require 'oai-relay/record_collection'
end

