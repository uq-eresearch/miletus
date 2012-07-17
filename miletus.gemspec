Gem::Specification.new do |s|
  s.name        = 'miletus'
  s.version     = '0.0.1'
  s.date        = '2012-07-13'
  s.summary     = "Miletus"
  s.description = "Miletus research collection metadata aggregator"
  s.authors     = ["Tim Dettrick", "Hoylen Sue"]
  s.email       = 't.dettrick@uq.edu.au'
  s.files       = ["lib/**/*.rb"]

  # These dependencies are only for people who work on this gem
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'sqlite3'
end