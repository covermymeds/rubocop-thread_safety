# frozen_string_literal: true

RSpec.describe RuboCop::Cop::ThreadSafety::InstanceVariableInClassMethod do
  subject(:cop) { described_class.new }

  it 'registers an offense for assigning to an ivar in a class method' do
    expect_offense(<<-RUBY.strip_indent)
      class Test
        def self.some_method(params)
          @params = params
          ^^^^^^^ Avoid instance variables in class methods.
        end
      end
    RUBY
  end

  it 'registers no offense when the assignment is synchronized by a mutex' do
    expect_no_offenses(<<-RUBY.strip_indent)
      class Test
        SEMAPHORE = Mutex.new
        def self.some_method(params)
          SEMAPHORE.synchronize do
            @params = params
          end
        end
      end
    RUBY
  end

  it 'registers no offense when memoization is synchronized by a mutex' do
    expect_no_offenses(<<-RUBY.strip_indent)
      class Test
        SEMAPHORE = Mutex.new
        def self.types
          SEMAPHORE
            .synchronize { @all_types ||= type_class.all }
        end
      end
    RUBY
  end

  it 'registers an offense for reading an ivar in a class method' do
    expect_offense(<<-RUBY.strip_indent)
      class Test
        def self.some_method
          do_work(@params)
                  ^^^^^^^ Avoid instance variables in class methods.
        end
      end
    RUBY
  end

  it 'registers an offense for assigning an ivar in module ClassMethods' do
    expect_offense(<<-RUBY.strip_indent)
      module ClassMethods
        def some_method(params)
          @params = params
          ^^^^^^^ Avoid instance variables in class methods.
        end
      end
    RUBY
  end

  it 'registers an offense for assigning an ivar in a class singleton method' do
    expect_offense(<<-RUBY.strip_indent)
      class Test
        class << self
          def some_method(params)
            @params = params
            ^^^^^^^ Avoid instance variables in class methods.
          end
        end
      end
    RUBY
  end

  it 'registers an offense for assigning an ivar in define_singleton_method' do
    expect_offense(<<-RUBY.strip_indent)
      class Test
        define_singleton_method(:some_method) do |params|
          @params = params
          ^^^^^^^ Avoid instance variables in class methods.
        end
      end
    RUBY
  end

  it 'registers an offense for ivar_get in a class method' do
    expect_offense(<<-RUBY.strip_indent)
      class Test
        def self.some_method
          do_work(instance_variable_get(:@params))
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid instance variables in class methods.
        end
      end
    RUBY
  end

  it 'registers an offense for ivar_set in a class singleton method' do
    expect_offense(<<-RUBY.strip_indent)
      class Test
        class << self
          def some_method(name, params)
            instance_variable_set(:"@\#{name}", params)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid instance variables in class methods.
          end
        end
      end
    RUBY
  end

  it 'registers an offense for ivar_set in module ClassMethods' do
    expect_offense(<<-RUBY.strip_indent)
      module ClassMethods
        def some_method(params)
          instance_variable_set(:@params, params)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid instance variables in class methods.
        end
      end
    RUBY
  end

  it 'registers an offense for ivar_set in define_singleton_method' do
    expect_offense(<<-RUBY.strip_indent)
      class Test
        define_singleton_method(:some_method) do |params|
          instance_variable_set(:@params, params)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid instance variables in class methods.
        end
      end
    RUBY
  end

  it 'registers no offense for using ivar_get on object in a class method' do
    expect_no_offenses(<<-RUBY.strip_indent)
      class Test
        def self.some_method(obj, params)
          obj.instance_variable_get(:@params)
        end
      end
    RUBY
  end

  it 'registers no offense for using ivar_set on object in a class method' do
    expect_no_offenses(<<-RUBY.strip_indent)
      class Test
        class << self
          def some_method(obj, params)
            obj.instance_variable_set(:@params, params)
          end
        end
      end
    RUBY
  end

  it 'registers no offense for using an ivar in an instance method' do
    expect_no_offenses(<<-RUBY.strip_indent)
      class Test
        def some_method(params)
          @params = params
          do_work(@params)
        end
      end
    RUBY
  end

  it 'registers no offense for using ivar methods in an instance method' do
    expect_no_offenses(<<-RUBY.strip_indent)
      class Test
        def some_method(params)
          instance_variable_set(:@params, params)
          do_work(instance_variable_get(:@params))
        end
      end
    RUBY
  end

  it 'registers no offense for using an ivar in a module below ClassMethods' do
    expect_no_offenses(<<-RUBY.strip_indent)
      module ClassMethods
        module Other
          def some_method(params)
            @params = params
          end
        end
      end
    RUBY
  end
end
