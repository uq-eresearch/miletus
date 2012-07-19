# More info at https://github.com/guard/guard#readme

guard :bundler do
  watch('Gemfile')
end

guard :rspec, :cli => "--color --format nested --fail-fast --drb" do
  watch(%r{(lib|spec)/.+\.rb})
end

guard :rails, :start_on_start => false do
  watch(%r{(app|config)/.+\.rb})
end