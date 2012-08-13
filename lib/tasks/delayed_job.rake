require 'delayed/tasks'

task :sync_output_and_load_miletus do
  STDERR.sync = STDOUT.sync = true
  require 'miletus'
end

# Enhance existing worker job
Rake::Task['jobs:work'].enhance([:sync_output_and_load_miletus])

