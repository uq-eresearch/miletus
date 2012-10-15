# More info at https://github.com/guard/guard#readme

guard :bundler do
  watch('Gemfile')
end

guard 'brakeman' do
  watch(%r{^app/.+\.(erb|haml|rhtml|rb)$})
  watch(%r{^config/.+\.rb$})
  watch(%r{^lib/.+\.rb$})
  watch('Gemfile')
end

guard 'rails_best_practices', :exclude => 'db/schema.rb' do
  watch(%r{^app/(.+)\.rb$})
  watch(%r{^config/(.+)\.rb$})
  watch(%r{^lib/(.+)\.rb$})
  watch(%r{^spec/(.+)\.rb$})
end

guard :rspec, :cli => "--color --format nested --fail-fast --drb" do
  watch(%r{^app/(.+)\.rb$})
  watch(%r{^app/models/(.+)\.rb$})
  watch(%r{^config/(.+)\.rb$})
  watch(%r{^lib/(.+)\.rb$})
  watch(%r{^spec/(.+)\.rb$})
end
