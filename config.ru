# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

if Rails.env.profile?
  require 'ruby-prof'
  FileUtils.mkdir_p '/tmp/miletus-profile' rescue nil
  use Rack::RubyProf, :path => '/tmp/miletus-profile'
end

run Miletus::Application
