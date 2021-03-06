begin
  require 'yard/rake/yardoc_task'

  desc 'Generate docs'
  task :doc => ['doc:yard']

  namespace :doc do
    desc 'Generate Yardoc documentation'
    YARD::Rake::YardocTask.new do |yardoc|
      yardoc.name = 'yard'
      yardoc.options = ['--verbose']
    end
  end
rescue LoadError
  # We may be in production, so just skip adding this task
end

