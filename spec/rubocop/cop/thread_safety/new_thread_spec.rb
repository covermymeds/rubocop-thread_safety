# encoding: utf-8
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::ThreadSafety::NewThread do
  subject(:cop) { described_class.new }

  it 'registers an offense for starting a new thread' do
    inspect_source(cop, 'Thread.new { do_work }')
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages)
      .to eq(['Avoid starting new threads.'])
    expect(cop.highlights).to eq(['Thread.new'])
  end

  it 'does not register an offense for calling new on other classes' do
    inspect_source(cop, 'Other.new { do_work }')
    expect(cop.offenses.size).to eq(0)
  end
end
