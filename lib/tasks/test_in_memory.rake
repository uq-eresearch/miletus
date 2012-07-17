# Our tests use an in-memory database, so no database migration is required
Rake::Task["db:test:prepare"].clear