require 'rubygems'
require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

def start_simplecov
  require 'simplecov'
  SimpleCov.start :rails
  require 'miletus'
end

Spork.prefork do
  # The Spork.prefork block is run only once when the spork server is started.
  # You typically want to place most of your (slow) initializer code in here, in
  # particular, require'ing any 3rd-party gems that you don't normally modify
  # during development.

  # SimpleCov initialisation, as demonstrated in:
  # https://github.com/colszowka/simplecov/issues/42#issuecomment-4440284
  start_simplecov unless ENV['DRB']

  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'

  RSpec.configure do |config|
    # ## Mock Framework
    #
    # If you prefer to use mocha, flexmock or RR,
    # uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr

    # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
    config.fixture_path = "#{::Rails.root}/spec/fixtures"

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = true

    # If true, the base class of anonymous controllers will be inferred
    # automatically. This will be the default behavior in future versions of
    # rspec-rails.
    config.infer_base_class_for_anonymous_controllers = false

    # Run specs in random order to surface order dependencies. If you find an
    # order dependency and want to debug it, you can fix the order by providing
    # the seed, which is printed after each run.
    #     --seed 1234
    config.order = "random"

    # Rollback the database between tests
    config.around do |example|
      ActiveRecord::Base.transaction do
        example.run
        raise ActiveRecord::Rollback
      end
    end

    # Mixin namespace helpers
    config.include Miletus::NamespaceHelper

  end
end

Spork.each_run do
  # The Spork.each_run block is run each time you run your specs.  In case you
  # need to load files that tend to change during development,
  # require them here.
  # With Rails, your application modules are loaded automatically, so sometimes
  # this block can remain empty.

  # SimpleCov initialisation
  start_simplecov if ENV['DRB']

  ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"])
  ActiveRecord::Migrator.up "db/migrate"

  # Set up the VCR to record/playback
  require 'vcr'
  VCR.configure do |c|
    c.allow_http_connections_when_no_cassette = true
    c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
    c.hook_into :webmock # or :fakeweb
  end

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
end






