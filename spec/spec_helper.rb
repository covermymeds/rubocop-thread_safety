require 'pry'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rubocop-thread_safety'

rubocop_path = File.join(File.dirname(__FILE__), '../vendor/rubocop')

unless File.directory?(rubocop_path)
  abort 'Run `bin/setup` to get a working development environment.'
end

Dir["#{rubocop_path}/spec/support/**/*.rb"].each { |f| require f }
