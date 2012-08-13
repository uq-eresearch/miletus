source 'https://rubygems.org'

gem 'rails', '>= 3.2.6'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3'


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

gem 'activerecord'
gem 'delayed_job_active_record'
gem 'oai', :git => 'https://github.com/tjdett/ruby-oai.git', :branch => 'next'
gem 'rake'
gem 'libxml-ruby'
gem 'nokogiri'
gem 'foreman'
gem 'clockwork'
gem 'activerecord-postgresql-adapter'
gem 'pg'
gem 'realrand' # For generating secret token
gem 'equivalent-xml'

gem 'twitter-bootstrap-rails'
gem 'haml-rails'

gem 'sru', '~> 0.0.9'

group :test do
  gem 'webmock' # For VCR
end

group :test, :development do
  gem 'rspec-rails'
  gem 'minitest'
  gem 'simplecov', :require => false
  gem 'spork' # For running a test server (and spec_helper.rb refers to it)
  gem 'brakeman' # For security testing
  gem 'vcr' # For playing back remote service tests
end

group :development do
  gem 'rails_best_practices'
  gem 'guard'
  gem 'guard-brakeman'
  gem 'guard-bundler'
  gem 'guard-rails_best_practices'
  gem 'guard-rspec'
  gem 'debugger'
  gem 'pry-rails'
  gem 'libnotify', :require => false unless RUBY_PLATFORM =~ /linux/i
end
