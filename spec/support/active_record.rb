require 'active_record'

# Based on:
# http://iain.nl/testing-activerecord-in-isolation

ActiveRecord::Base.establish_connection\
  :adapter => "sqlite3",
  :database => ":memory:"
ActiveRecord::Migrator.up "db/migrate"

RSpec.configure do |config|
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end