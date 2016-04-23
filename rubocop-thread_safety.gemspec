# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rubocop/thread_safety/version'

Gem::Specification.new do |spec|
  spec.name          = "rubocop-thread_safety"
  spec.version       = Rubocop::ThreadSafety::VERSION
  spec.authors       = ["Michael Gee"]
  spec.email         = ["michaelpgee@gmail.com"]

  spec.summary       = 'Thread-safety checks via static analysis'
  spec.description   = <<-end_description
    Thread-safety checks via static analysis.
    A plugin for the RuboCop code style enforcing & linting tool.
  end_description
  spec.homepage      = 'https://github.com/covermymeds/rubocop-thread_safety'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
