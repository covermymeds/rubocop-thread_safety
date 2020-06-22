# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'the LICENSE' do
  let(:license) { Pathname('LICENSE.txt') }

  it 'exists' do
    expect(license).to exist
  end

  it 'contains a copyright statement for the current year' do
    expect(license.read).to match(/Copyright 2016-#{Date.today.year}/)
  end

  it 'is referenced from the README' do
    readme = Pathname('README.md').read
    expect(readme).to match(
      /Copyright .* 2016-#{Date.today.year}.*LICENSE.txt/m
    )
  end
end
