# frozen_string_literal: true

appraise 'rubocop-0.53' do
  gem 'rubocop', '~> 0.53.0'
end

appraise 'rubocop-0.81' do
  gem 'rubocop', '~> 0.81.0'
end

if Gem::Requirement.new('>= 2.4.0')
                   .satisfied_by?(Gem::Version.new(RUBY_VERSION))
  appraise 'rubocop-0.86' do
    gem 'rubocop', '~> 0.86.0'
  end
end
