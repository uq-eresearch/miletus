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
  gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'
gem 'underscore-rails'
gem "google-code-prettify-rails"

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
gem 'psych', '>= 1.3.4' # Newer Psych YAML parser than bundled for MRI => Faster
gem 'ratom' # For Atom RDC feed parsing
gem 'meta-tags', :require => 'meta_tags' # For UI SEO
gem 'redcarpet' # For Markdown-based static pages
gem 'paperclip', ">= 3.2" # For large file attachments

gem 'less-rails' # Needed for Bootstrap LESS compilation
gem 'twitter-bootstrap-rails'
gem 'font-awesome-rails'
gem 'haml-rails'
gem 'rails-timeago'
gem 'google-analytics-rails'

gem 'locale'
gem 'memoize'
gem 'algorithms' # For efficient data structures like Stack
gem 'uuidtools' # For UUID generation
gem 'rdf'
gem 'rdf-rdfa'
gem 'rdf-rdfxml'
gem 'georuby', :require => 'geo_ruby',
  :git => 'https://github.com/tjdett/georuby.git', :branch => 'test-fixes'

gem 'deface', '>= 1.0.0.rc1'
gem 'activeadmin'

gem 'sru',
  :git => 'https://github.com/tjdett/sru-ruby.git', :branch => 'proxy-handling'

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
  gem 'yard' # Documentation
end

group :development do
  gem 'code_analyzer' # For Rails BP
  gem 'rails_best_practices', '>= 1.11.0' # Has auto-ignore of schema.rb
  gem 'guard'
  gem 'guard-brakeman'
  gem 'guard-bundler'
  gem 'guard-rails_best_practices'
  gem 'guard-rspec'
  gem 'debugger'
  gem 'flog' # Cyclomatic complexity reporting
  gem 'pry-rails'
  gem 'ruby-prof'
  gem 'rb-inotify', '~> 0.8.8'
end
