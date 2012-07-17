# Required for Bundler
require 'bundler/setup'

# Import Rake task for RSpec
require 'rspec/core/rake_task'
# Import Rake task for gem packaging
require 'rubygems/package_task'

# Import DelayedJob tasks
require 'delayed_job_active_record'
require 'delayed/tasks'

# Add lib/ to path
$:.unshift File.join(File.dirname(__FILE__), 'lib')

#spec = Gem::Specification.load(Dir['*.gemspec'].first)
#gem = Rake::GemPackageTask.new(spec)
#gem.define




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

namespace :harvest do
  namespace :oaipmh_rifcs do
    namespace :record_collection do

      desc "Add a Record Collection"
      task :add, [:endpoint] => [:environment] do |t, args|
        include Miletus::Harvest::OAIPMH::RIFCS
        RecordCollection.new(:endpoint => args[:endpoint]).save!
      end

    end
  end
end

task :environment do |t|
  Delayed::Worker.destroy_failed_jobs = false
  STDOUT.sync = true
  require 'active_record'
  @connection = ActiveRecord::Base.establish_connection(
    ENV['DATABASE_URL']
  )
  ActiveRecord::Migrator.up "db/migrate"
  require 'miletus'
end

