desc "Run clockwork scheduler"
task :clock => :environment do |t|
  STDERR.sync = STDOUT.sync = true
  require File.join(File.dirname(__FILE__), '..', '..', 'clock')
  Clockwork.run
end