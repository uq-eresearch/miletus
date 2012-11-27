require 'yard/rake/yardoc_task'

desc 'Generate docs'
task :doc => ['doc:images:compile', 'doc:yard']

namespace :doc do
  desc 'Generate Yardoc documentation'
  YARD::Rake::YardocTask.new do |yardoc|
    yardoc.name = 'yard'
    yardoc.options = ['--verbose']
    #yardoc.files = [
    #  'lib/**/*.rb', 'README.md', 'COPYING'
    #]
  end
  namespace :images do
    desc "Compile DOT files into images"
    task :compile do
      Dir.glob('doc/images/*.dot') do |source_path|
        image_path = source_path.gsub(/\.dot$/, '.png')
        puts "Generating #{image_path} from #{source_path}"
        `dot -T png -o #{image_path} #{source_path}`
      end
    end
  end
end


