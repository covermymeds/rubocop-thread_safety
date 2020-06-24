# frozen_string_literal: true

RSpec.describe RuboCop::Cop::ThreadSafety::ClassAndModuleAttributes do
  subject(:cop) { described_class.new }

  context 'when in the singleton class' do
    it 'registers an offense for `attr`' do
      expect_offense(<<-RUBY.strip_indent)
        module Test
          class << self
            attr :foobar
            ^^^^^^^^^^^^ Avoid mutating class and module attributes.
          end
        end
      RUBY
    end

    it 'registers an offense for `attr_accessor`' do
      expect_offense(<<-RUBY.strip_indent)
        module Test
          class << self
            attr_accessor :foobar
            ^^^^^^^^^^^^^^^^^^^^^ Avoid mutating class and module attributes.
          end
        end
      RUBY
    end

    it 'registers an offense for `attr_writer`' do
      expect_offense(<<-RUBY.strip_indent)
        module Test
          class << self
            attr_writer :foobar
            ^^^^^^^^^^^^^^^^^^^ Avoid mutating class and module attributes.
          end
        end
      RUBY
    end

    it 'registers no offense for `attr_reader`' do
      expect_no_offenses(<<-RUBY.strip_indent)
        module Test
          class << self
            attr_reader :foobar
          end
        end
      RUBY
    end

    it 'registers an offense for `attr_internal`' do
      expect_offense(<<-RUBY.strip_indent)
        module Test
          class << self
            attr_internal :foobar
            ^^^^^^^^^^^^^^^^^^^^^ Avoid mutating class and module attributes.
          end
        end
      RUBY
    end

    it 'registers an offense for `attr_internal_accessor`' do
      expect_offense(<<-RUBY.strip_indent)
        module Test
          class << self
            attr_internal_accessor :foobar
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid mutating class and module attributes.
          end
        end
      RUBY
    end

    it 'registers an offense for `attr_internal_writer`' do
      expect_offense(<<-RUBY.strip_indent)
        module Test
          class << self
            attr_internal_writer :foobar
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid mutating class and module attributes.
          end
        end
      RUBY
    end

    it 'registers no offense for `attr_internal_reader`' do
      expect_no_offenses(<<-RUBY.strip_indent)
        module Test
          class << self
            attr_internal_reader :foobar
          end
        end
      RUBY
    end
  end

  it 'registers an offense for `mattr_writer`' do
    expect_offense(<<-RUBY.strip_indent)
      module Test
        mattr_writer :foobar
        ^^^^^^^^^^^^^^^^^^^^ Avoid mutating class and module attributes.
      end
    RUBY
  end

  it 'registers an offense for `mattr_accessor`' do
    expect_offense(<<-RUBY.strip_indent)
      module Test
        mattr_accessor :foobar
        ^^^^^^^^^^^^^^^^^^^^^^ Avoid mutating class and module attributes.
      end
    RUBY
  end

  it 'registers an offense for `cattr_writer`' do
    expect_offense(<<-RUBY.strip_indent)
      class Test
        cattr_writer :foobar
        ^^^^^^^^^^^^^^^^^^^^ Avoid mutating class and module attributes.
      end
    RUBY
  end

  it 'registers an offense for `cattr_accessor`' do
    expect_offense(<<-RUBY.strip_indent)
      class Test
        cattr_accessor :foobar
        ^^^^^^^^^^^^^^^^^^^^^^ Avoid mutating class and module attributes.
      end
    RUBY
  end

  it 'registers an offense for `class_attribute`' do
    expect_offense(<<-RUBY.strip_indent)
      class Test
        class_attribute :foobar
        ^^^^^^^^^^^^^^^^^^^^^^^ Avoid mutating class and module attributes.
      end
    RUBY
  end

  it 'registers no offense for other class macro calls' do
    expect_no_offenses(<<-RUBY.strip_indent)
      class Test
        belongs_to :foobar
      end
    RUBY
  end
end
