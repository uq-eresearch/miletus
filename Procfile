web: bundle exec unicorn -p $PORT -c config/unicorn.rb
default_queue: bundle exec rake jobs:work QUEUE=""
lookup_queue: bundle exec rake jobs:work QUEUE=lookup
output_queue: bundle exec rake jobs:work QUEUE=output
clock: bundle exec rake clock
