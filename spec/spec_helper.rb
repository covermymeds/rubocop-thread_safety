# frozen_string_literal: true

begin
  require 'pry'
rescue LoadError
  # Pry isn't installed in CI.
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'rubocop-thread_safety'

require 'powerpack/string/strip_indent'
require 'rubocop/rspec/support'

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense

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
