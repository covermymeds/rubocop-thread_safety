begin
  require 'pry'
rescue LoadError # rubocop:disable Lint/HandleExceptions
  # Pry isn't installed in CI.
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rubocop-thread_safety'

rubocop_path = File.join(File.dirname(__FILE__), '../vendor/rubocop')

unless File.directory?(rubocop_path)
  abort 'Run `bin/setup` to get a working development environment.'
end

Dir["#{rubocop_path}/spec/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end

  if ENV.key? 'CI'
    config.before(:example, :focus) { raise 'Should not commit focused specs' }
  else
    config.filter_run focus: true
    config.run_all_when_everything_filtered = true
    config.fail_fast = ENV.key? 'RSPEC_FAIL_FAST'
  end

  config.disable_monkey_patching!

  config.order = :random

  Kernel.srand config.seed
end
