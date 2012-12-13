web: bundle exec unicorn -p $PORT -c config/unicorn.rb
job: bundle exec rake jobs:work QUEUE=""
lookup: bundle exec rake jobs:work QUEUE=lookup
clock: bundle exec rake clock
