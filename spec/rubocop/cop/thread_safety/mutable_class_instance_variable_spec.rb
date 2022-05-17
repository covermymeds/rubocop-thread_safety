# frozen_string_literal: true

RSpec.describe RuboCop::Cop::ThreadSafety::MutableClassInstanceVariable,
               :config do
  subject(:cop) { described_class.new(config) }
  let(:msg) { 'Freeze mutable objects assigned to class instance variables.' }
  if Gem::Requirement.new('< 0.69')
                     .satisfied_by?(Gem::Version.new(RuboCop::Version::STRING))
    let(:ruby_version) { 2.3 }
  end

  let(:prefix) { nil }
  let(:suffix) { nil }
  let(:indent) { '' }
  def surround(code)
    [
      prefix,
      code.split("\n").map { |line| "#{indent}#{line}" },
      suffix
    ].compact.join("\n")
  end

  shared_examples 'mutable objects' do |o|
    context 'when assigning with =' do
      it "registers an offense for #{o} assigned to a class ivar" do
        expect_offense(surround(<<~RUBY), o: o)
          @var = %{o}
                 ^{o} #{msg}
        RUBY

        expect_correction(surround(<<~RUBY))
          @var = #{o}.freeze
        RUBY
      end
    end

    context 'when assigning with ||=' do
      it "registers an offense for #{o} assigned to a class ivar" do
        expect_offense(surround(<<~RUBY), o: o)
          @var ||= %{o}
                   ^{o} #{msg}
        RUBY

        expect_correction(surround(<<~RUBY))
          @var ||= #{o}.freeze
        RUBY
      end
    end
  end

  shared_examples 'immutable objects' do |o|
    it "allows #{o} to be assigned to a class ivar" do
      expect_no_offenses(surround("@var = #{o}"))
    end

    it "allows #{o} to be ||= to a class ivar" do
      expect_no_offenses(surround("@var ||= #{o}"))
    end
  end

  context 'when not directly in class / module' do
    context 'top level code' do
      it_behaves_like 'immutable objects', '[1, 2, 3]'
    end

    context 'inside a method' do
      let(:prefix) { "class Test\n  def some_method" }
      let(:suffix) { "  end\nend" }
      let(:indent) { '    ' }

      it_behaves_like 'immutable objects', '{ a: 1, b: 2 }'
    end

    context 'inside a class method' do
      let(:prefix) { "class Test\n  def self.some_method" }
      let(:suffix) { "  end\nend" }
      let(:indent) { '    ' }

      it_behaves_like 'immutable objects', '%w(a b c)'
    end

    context 'inside a class singleton method' do
      let(:prefix) do
        <<~RUBY
          class Test
            class << self
              def some_method
        RUBY
      end
      let(:suffix) do
        <<~RUBY
              end
            end
          end
        RUBY
      end
      let(:indent) { ' ' * 6 }

      it_behaves_like 'immutable objects', '%i{a b c}'
    end

    context 'inside define_singleton_method' do
      let(:prefix) { "class Test\n  define_singleton_method(:name) do" }
      let(:suffix) { "  end\nend" }
      let(:indent) { '    ' }

      it_behaves_like 'immutable objects', '[1, 2]'
    end

    context 'inside define_method' do
      let(:prefix) { "class Test\n  define_method(:name) do" }
      let(:suffix) { "  end\nend" }
      let(:indent) { '    ' }

      it_behaves_like 'immutable objects', '[1, 2]'
    end
  end

  context 'Strict: false' do
    let(:cop_config) { { 'EnforcedStyle' => 'literals' } }

    %w[class module].each do |mod|
      context "inside a #{mod}" do
        let(:prefix) { "#{mod} Test" }
        let(:suffix) { 'end' }
        let(:indent) { '  ' }

        it_behaves_like 'mutable objects', '[1, 2, 3]'
        it_behaves_like 'mutable objects', '%w(a b c)'
        it_behaves_like 'mutable objects', '{ a: 1, b: 2 }'
        it_behaves_like 'mutable objects', "'str'"
        it_behaves_like 'mutable objects', %("\#{30 + 12}nd")

        it_behaves_like 'immutable objects', '1'
        it_behaves_like 'immutable objects', '2.1'
        it_behaves_like 'immutable objects', ':sym'
        it_behaves_like 'immutable objects', 'CONST'
        it_behaves_like 'immutable objects', 'FOO + BAR'
        it_behaves_like 'immutable objects', 'FOO - BAR'
        it_behaves_like 'immutable objects', "'foo' + BAR"
        it_behaves_like 'immutable objects', "ENV['foo']"

        it_behaves_like 'immutable objects', '[1, 2].freeze'
        it_behaves_like 'immutable objects', 'Something.new'

        it 'registers no offense for class variable' do
          expect_no_offenses(surround('@@list = [1, 2]'))
        end

        context 'inside an if statement' do
          let(:prefix) { "#{mod} Test\n  if something" }
          let(:suffix) { "  end\nend" }
          let(:indent) { '    ' }

          it_behaves_like 'mutable objects', '[1, 2, 3]'
        end

        context 'splat expansion' do
          context 'expansion of a range' do
            it 'registers an offense' do
              expect_offense(surround(<<~RUBY))
                @var = *1..10
                       ^^^^^^ #{msg}
              RUBY

              expect_correction(surround(<<~RUBY))
                @var = (1..10).to_a.freeze
              RUBY
            end

            context 'with parentheses' do
              it 'registers an offense' do
                expect_offense(surround(<<~RUBY))
                  @var = *(1..10)
                         ^^^^^^^^ #{msg}
                RUBY

                expect_correction(surround(<<~RUBY))
                  @var = (1..10).to_a.freeze
                RUBY
              end
            end
          end
        end

        context 'when assigning an array without brackets' do
          it 'adds brackets when auto-correcting' do
            expect_offense(surround(<<~RUBY))
              @var = YYY, ZZZ
                     ^^^^^^^^ #{msg}
            RUBY

            expect_correction(surround(<<~RUBY))
              @var = [YYY, ZZZ].freeze
            RUBY
          end

          it 'does not add brackets to %w() arrays' do
            expect_offense(surround(<<~RUBY))
              @var = %w(YYY ZZZ)
                     ^^^^^^^^^^^ #{msg}
            RUBY

            expect_correction(surround(<<~RUBY))
              @var = %w(YYY ZZZ).freeze
            RUBY
          end
        end

        context 'when assigning a range (irange) without parentheses' do
          it 'adds parentheses when auto-correcting' do
            expect_offense(surround(<<~RUBY))
              @var = 1..99
                     ^^^^^ #{msg}
            RUBY

            expect_correction(surround(<<~RUBY))
              @var = (1..99).freeze
            RUBY
          end

          it 'does not add parenetheses to range enclosed in parentheses' do
            expect_offense(surround(<<~RUBY))
              @var = (1..99)
                     ^^^^^^^ #{msg}
            RUBY

            expect_correction(surround(<<~RUBY))
              @var = (1..99).freeze
            RUBY
          end
        end

        context 'when assigning a range (erange) without parentheses' do
          it 'adds parentheses when auto-correcting' do
            expect_offense(surround(<<~RUBY))
              @var = 1...99
                     ^^^^^^ #{msg}
            RUBY

            expect_correction(surround(<<~RUBY))
              @var = (1...99).freeze
            RUBY
          end

          it 'does not add parentheses to range enclosed in parentheses' do
            expect_offense(surround(<<~RUBY))
              @var = (1...99)
                     ^^^^^^^^ #{msg}
            RUBY

            expect_correction(surround(<<~RUBY))
              @var = (1...99).freeze
            RUBY
          end
        end

        context 'with a frozen string literal' do
          # TODO: It is not yet decided when frozen string will be the default.
          # It has been abandoned for Ruby 3.0 but may default in the future.
          # So these tests are given a provisional value of 4.0.
          if defined?(RuboCop::TargetRuby) &&
             RuboCop::TargetRuby.supported_versions.include?(4.0)
            context 'when the target ruby version >= 4.0' do
              let(:ruby_version) { 4.0 }

              context 'when the frozen_string_literal comment is missing' do
                it_behaves_like 'immutable objects', %("\#{a}")
              end

              context 'when the frozen_string_literal_comment is true' do
                let(:prefix) { "# frozen_string_literal: true\n#{super()}" }

                it_behaves_like 'immutable objects', %("\#{a}")
              end

              context 'when the frozen_string_literal_comment is false' do
                let(:prefix) { "# frozen_string_literal: false\n#{super()}" }

                it_behaves_like 'immutable objects', %("\#{a}")
              end
            end
          end

          context 'when the frozen_string_literal comment is missing' do
            it_behaves_like 'mutable objects', %("\#{a}")
          end

          context 'when the frozen_string_literal comment is true' do
            let(:prefix) { "# frozen_string_literal: true\n#{super()}" }

            it_behaves_like 'immutable objects', %("\#{a}")
          end

          context 'when the frozen_string_literal comment is false' do
            let(:prefix) { "# frozen_string_literal: false\n#{super()}" }

            it_behaves_like 'mutable objects', %("\#{a}")
          end
        end

        context 'when assigning to multiple class ivars' do
          it 'registers an offense when first object is mutable' do
            expect_offense(surround(<<~RUBY))
              @a, @b = [1], 1
                       ^^^ #{msg}
            RUBY

            expect_correction(surround(<<~RUBY))
              @a, @b = [1].freeze, 1
            RUBY
          end

          it 'registers an offense when middle object is mutable' do
            expect_offense(surround(<<~RUBY))
              @a, @b, @c = [1, { a: 1 }, [3].freeze]
                               ^^^^^^^^ #{msg}
            RUBY

            expect_correction(surround(<<~RUBY))
              @a, @b, @c = [1, { a: 1 }.freeze, [3].freeze]
            RUBY
          end

          it 'registers an offense when last object is mutable' do
            expect_offense(surround(<<~RUBY))
              @a, _, @c = 1, [2].freeze, 'foo'
                                         ^^^^^ #{msg}
            RUBY

            expect_correction(surround(<<~RUBY))
              @a, _, @c = 1, [2].freeze, 'foo'.freeze
            RUBY
          end

          it 'registers an offense for multiple mutable objects' do
            expect_offense(surround(<<~RUBY))
              @a, @b, @c = 'foo', [2], 3
                           ^^^^^ #{msg}
                                  ^^^ #{msg}
            RUBY

            expect_correction(surround(<<~RUBY))
              @a, @b, @c = 'foo'.freeze, [2].freeze, 3
            RUBY
          end
        end

        it 'freezes a heredoc' do
          expect_offense(surround(<<~RUBY))
            @var = <<~HERE
                   ^^^^^^^ #{msg}
              content
            HERE
          RUBY

          expect_correction(surround(<<~RUBY))
            @var = <<~HERE.freeze
              content
            HERE
          RUBY
        end
      end
    end
  end

  context 'Strict: true' do
    let(:cop_config) { { 'EnforcedStyle' => 'strict' } }

    %w[class module].each do |mod|
      context "inside a #{mod}" do
        let(:prefix) { "#{mod} Test" }
        let(:suffix) { 'end' }
        let(:indent) { '  ' }

        it_behaves_like 'mutable objects', '[1, 2, 3]'
        it_behaves_like 'mutable objects', '%w(a b c)'
        it_behaves_like 'mutable objects', '{ a: 1, b: 2 }'
        it_behaves_like 'mutable objects', "'str'"
        it_behaves_like 'mutable objects', %("\#{30 + 12}nd")
        it_behaves_like 'mutable objects', 'Something.new'

        it_behaves_like 'immutable objects', '1'
        it_behaves_like 'immutable objects', '2.1'
        it_behaves_like 'immutable objects', ':sym'
        it_behaves_like 'immutable objects', 'CONST'
        it_behaves_like 'immutable objects', '::CONST'
        it_behaves_like 'immutable objects', 'Namespace::CONST'
        it_behaves_like 'immutable objects', '::Namespace::CONST'
        it_behaves_like 'immutable objects', 'Struct.new'
        it_behaves_like 'immutable objects', '::Struct.new'
        it_behaves_like 'immutable objects', 'Struct.new(:a, :b)'
        it_behaves_like 'immutable objects', '::Struct.new(:a, :b)'
        it_behaves_like 'immutable objects', <<~RUBY
          Struct.new(:node) do
            def assignment?
              true
            end
          end
        RUBY
        it_behaves_like 'immutable objects', <<~RUBY
          ::Struct.new(:node) do
            def assignment?
              true
            end
          end
        RUBY

        it_behaves_like 'immutable objects', '[1, 2].freeze'
        it_behaves_like 'immutable objects', 'Something.new.freeze'
        it_behaves_like 'immutable objects', '::Something.new.freeze'

        context 'with thread-safe data structure' do
          it_behaves_like 'immutable objects', 'Queue.new'
          it_behaves_like 'immutable objects', '::Queue.new'
          it_behaves_like 'immutable objects', 'ThreadSafe::Array.new'
          it_behaves_like 'immutable objects', '::ThreadSafe::Hash.new'
          it_behaves_like 'immutable objects', 'ThreadSafe::Hash.new { false }'
          it_behaves_like 'immutable objects', 'Concurrent::Array.new'
          it_behaves_like 'immutable objects', 'Concurrent::Hash.new'
          it_behaves_like 'immutable objects', '::Concurrent::Map.new'
          it_behaves_like 'immutable objects', <<~RUBY
            Concurrent::Map.new(initial_capacity: 4)
          RUBY
          it_behaves_like 'immutable objects', <<~RUBY
            Concurrent::Map.new do |h, key|
              h.fetch_or_store(key, Concurrent::Map.new)
            end
          RUBY
          it_behaves_like 'immutable objects',
                          'Concurrent::ContinuationQueue.new'
          it_behaves_like 'immutable objects',
                          'Concurrent::ThreadPoolExecutor.new(options)'
          it_behaves_like 'immutable objects',
                          'Concurrent::AtomicBoolean.new(true)'
          it_behaves_like 'immutable objects',
                          'Concurrent::ThreadSafe::Util::Adder.new'

          it_behaves_like 'mutable objects', '[Queue.new]'
          it_behaves_like 'mutable objects', '[ThreadSafe::Hash.new { false }]'
          it_behaves_like 'mutable objects',
                          '[Concurrent::ThreadSafe::Util::Adder.new]'
        end

        it 'registers no offense for class variable' do
          expect_no_offenses(surround('@@list = [1, 2]'))
        end

        context 'inside an if statement' do
          let(:prefix) { "#{mod} Test\n  if something" }
          let(:suffix) { "  end\nend" }
          let(:indent) { '    ' }

          it_behaves_like 'mutable objects', '[1, 2, 3]'
        end

        context 'splat expansion' do
          context 'expansion of a range' do
            it 'registers an offense' do
              expect_offense(surround(<<~RUBY))
                @var = *1..10
                       ^^^^^^ #{msg}
              RUBY

              expect_correction(surround(<<~RUBY))
                @var = (1..10).to_a.freeze
              RUBY
            end

            context 'with parentheses' do
              it 'registers an offense' do
                expect_offense(surround(<<~RUBY))
                  @var = *(1..10)
                         ^^^^^^^^ #{msg}
                RUBY

                expect_correction(surround(<<~RUBY))
                  @var = (1..10).to_a.freeze
                RUBY
              end
            end
          end
        end

        context 'when assigning with an operator' do
          shared_examples 'operator methods' do |o|
            it 'registers an offense' do
              expect_offense(surround(<<~RUBY), o: o)
                @var = FOO %{o} BAR
                       ^^^^^{o}^^^^ #{msg}
              RUBY

              expect_correction(surround(<<~RUBY))
                @var = (FOO #{o} BAR).freeze
              RUBY
            end
          end

          it_behaves_like 'operator methods', '+'
          it_behaves_like 'operator methods', '-'
          it_behaves_like 'operator methods', '*'
          it_behaves_like 'operator methods', '/'
          it_behaves_like 'operator methods', '%'
          it_behaves_like 'operator methods', '**'
        end

        context 'when assigning with multiple operator calls' do
          it 'registers an offense' do
            expect_offense(surround(<<~RUBY))
              @a = [1].freeze
              @b = [2].freeze
              @c = [3].freeze
              @var = @a + @b + @c
                     ^^^^^^^^^^^^ #{msg}
            RUBY

            expect_correction(surround(<<~RUBY))
              @a = [1].freeze
              @b = [2].freeze
              @c = [3].freeze
              @var = (@a + @b + @c).freeze
            RUBY
          end
        end

        context 'methods and operators that produce frozen objects' do
          it_behaves_like 'immutable objects', "ENV['foo'] || 'bar'"
          it_behaves_like 'immutable objects', 'FOO + 2'
          it_behaves_like 'immutable objects', '1 + 2'
          it_behaves_like 'immutable objects', 'FOO + 2.1'
          it_behaves_like 'immutable objects', '1.2 + 3.4'
          it_behaves_like 'immutable objects', 'FOO == BAR'

          describe 'checking fixed size' do
            it_behaves_like 'immutable objects', "'foo'.count"
            it_behaves_like 'immutable objects', "'foo'.count('f')"
            it_behaves_like 'immutable objects', '[1, 2, 3].count { |n| n > 2 }'
            it_behaves_like 'immutable objects', '[1, 2].count(2) { |n| n > 2 }'
            it_behaves_like 'immutable objects', "'foo'.length"
            it_behaves_like 'immutable objects', "'foo'.size"
          end
        end

        context 'operators that produce unfrozen objects' do
          it 'registers an offense when operating on a constant and a string' do
            expect_offense(surround(<<~RUBY))
              @var = FOO + 'bar'
                     ^^^^^^^^^^^ #{msg}
            RUBY

            expect_correction(surround(<<~RUBY))
              @var = (FOO + 'bar').freeze
            RUBY
          end

          it 'registers an offense when operating on multiple strings' do
            expect_offense(surround(<<~RUBY))
              @var = 'foo' + 'bar' + 'baz'
                     ^^^^^^^^^^^^^^^^^^^^^ #{msg}
            RUBY

            expect_correction(surround(<<~RUBY))
              @var = ('foo' + 'bar' + 'baz').freeze
            RUBY
          end
        end

        context 'when assigning an array without brackets' do
          it 'adds brackets when auto-correcting' do
            expect_offense(surround(<<~RUBY))
              @var = @a, @b
                     ^^^^^^ #{msg}
            RUBY

            expect_correction(surround(<<~RUBY))
              @var = [@a, @b].freeze
            RUBY
          end

          it 'does not add brackets to %w() arrays' do
            expect_offense(surround(<<~RUBY))
              @var = %w(YYY ZZZ)
                     ^^^^^^^^^^^ #{msg}
            RUBY

            expect_correction(surround(<<~RUBY))
              @var = %w(YYY ZZZ).freeze
            RUBY
          end
        end

        it 'freezes a heredoc' do
          expect_offense(surround(<<~RUBY))
            @var = <<~HERE
                   ^^^^^^^ #{msg}
              content
            HERE
          RUBY

          expect_correction(surround(<<~RUBY))
            @var = <<~HERE.freeze
              content
            HERE
          RUBY
        end

        context 'with a frozen string literal' do
          context 'when the frozen_string_literal comment is missing' do
            it_behaves_like 'mutable objects', %("\#{a}")
          end

          context 'when the frozen_string_literal comment is true' do
            let(:prefix) { "# frozen_string_literal: true\n#{super()}" }

            it_behaves_like 'immutable objects', %("\#{a}")
          end

          context 'when the frozen_string_literal comment is false' do
            let(:prefix) { "# frozen_string_literal: false\n#{super()}" }

            it_behaves_like 'mutable objects', %("\#{a}")
          end
        end

        context 'when assigning to multiple class ivars' do
          it 'registers an offense when first object is mutable' do
            expect_offense(surround(<<~RUBY))
              @a, @b = [1], 1
                       ^^^ #{msg}
            RUBY

            expect_correction(surround(<<~RUBY))
              @a, @b = [1].freeze, 1
            RUBY
          end

          it 'registers an offense when middle object is mutable' do
            expect_offense(surround(<<~RUBY))
              @a, @b, @c = [1, { a: 1 }, [3].freeze]
                               ^^^^^^^^ #{msg}
            RUBY

            expect_correction(surround(<<~RUBY))
              @a, @b, @c = [1, { a: 1 }.freeze, [3].freeze]
            RUBY
          end

          it 'registers an offense when last object is mutable' do
            expect_offense(surround(<<~RUBY))
              @a, _, @c = 1, [2].freeze, 'foo'
                                         ^^^^^ #{msg}
            RUBY

            expect_correction(surround(<<~RUBY))
              @a, _, @c = 1, [2].freeze, 'foo'.freeze
            RUBY
          end

          it 'registers an offense for multiple mutable objects' do
            expect_offense(surround(<<~RUBY))
              @a, @b, @c = 'foo', [2], 3
                           ^^^^^ #{msg}
                                  ^^^ #{msg}
            RUBY

            expect_correction(surround(<<~RUBY))
              @a, @b, @c = 'foo'.freeze, [2].freeze, 3
            RUBY
          end
        end
      end
    end
  end
end
