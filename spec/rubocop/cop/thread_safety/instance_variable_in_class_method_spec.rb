# encoding: utf-8
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::ThreadSafety::InstanceVariableInClassMethod do
  subject(:cop) { described_class.new }

  it 'registers an offense for assigning to an ivar in a class method' do
    inspect_source(cop,
                   ['class Test',
                    '  def self.some_method(params)',
                    '    @params = params',
                    '  end',
                    'end'])
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages)
      .to eq(['Avoid instance variables in class methods.'])
    expect(cop.highlights).to eq(['@params'])
  end

  it 'registers an offense for reading an ivar in a class method' do
    inspect_source(cop,
                   ['class Test',
                    '  def self.some_method',
                    '    do_work(@params)',
                    '  end',
                    'end'])
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages)
      .to eq(['Avoid instance variables in class methods.'])
    expect(cop.highlights).to eq(['@params'])
  end

  it 'registers an offense for assigning an ivar in a class singleton method' do
    inspect_source(cop,
                   ['class Test',
                    '  class << self',
                    '    def some_method(params)',
                    '      @params = params',
                    '    end',
                    '  end',
                    'end'])
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages)
      .to eq(['Avoid instance variables in class methods.'])
    expect(cop.highlights).to eq(['@params'])
  end

  it 'registers an offense for assigning an ivar in define_singleton_method' do
    inspect_source(cop,
                   ['class Test',
                    '  define_singleton_method(:some_method) do |params|',
                    '    @params = params',
                    '  end',
                    'end'])
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages)
      .to eq(['Avoid instance variables in class methods.'])
    expect(cop.highlights).to eq(['@params'])
  end

  it 'registers no offense for using an ivar in an instance method' do
    inspect_source(cop,
                   ['class Test',
                    '  def some_method(params)',
                    '    @params = params',
                    '    do_work(@params)',
                    '  end',
                    'end'])
    expect(cop.offenses.size).to eq(0)
  end
end
