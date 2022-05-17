# frozen_string_literal: true

module RuboCop
  module Cop
    module ThreadSafety
      # Avoid instance variables in class methods.
      #
      # @example
      #   # bad
      #   class User
      #     def self.notify(info)
      #       @info = validate(info)
      #       Notifier.new(@info).deliver
      #     end
      #   end
      #
      #   class Model
      #     class << self
      #       def table_name(name)
      #         @table_name = name
      #       end
      #     end
      #   end
      #
      #   class Host
      #     %i[uri port].each do |key|
      #       define_singleton_method("#{key}=") do |value|
      #         instance_variable_set("@#{key}", value)
      #       end
      #     end
      #   end
      #
      #   module Example
      #     module ClassMethods
      #       def test(params)
      #         @params = params
      #       end
      #     end
      #   end
      #
      #   module Example
      #     module_function
      #
      #     def test(params)
      #       @params = params
      #     end
      #   end
      #
      #   module Example
      #     def test(params)
      #       @params = params
      #     end
      #
      #     module_function :test
      #   end
      class InstanceVariableInClassMethod < Cop
        MSG = 'Avoid instance variables in class methods.'
        RESTRICT_ON_SEND = %i[
          instance_variable_set
          instance_variable_get
        ].freeze

        def_node_matcher :instance_variable_set_call?, <<~MATCHER
          (send nil? :instance_variable_set (...) (...))
        MATCHER

        def_node_matcher :instance_variable_get_call?, <<~MATCHER
          (send nil? :instance_variable_get (...))
        MATCHER

        def on_ivar(node)
          return unless class_method_definition?(node)
          return if method_definition?(node)
          return if synchronized?(node)

          add_offense(node, location: :name, message: MSG)
        end
        alias on_ivasgn on_ivar

        def on_send(node)
          return unless instance_variable_call?(node)
          return unless class_method_definition?(node)
          return if method_definition?(node)
          return if synchronized?(node)

          add_offense(node, message: MSG)
        end

        private

        def class_method_definition?(node)
          return false if method_definition?(node)

          in_defs?(node) ||
            in_def_sclass?(node) ||
            in_def_class_methods?(node) ||
            in_def_module_function?(node) ||
            singleton_method_definition?(node)
        end

        def in_defs?(node)
          node.ancestors.any? do |ancestor|
            ancestor.type == :defs
          end
        end

        def in_def_sclass?(node)
          defn = node.ancestors.find do |ancestor|
            ancestor.type == :def
          end

          defn&.ancestors&.any? do |ancestor|
            ancestor.type == :sclass
          end
        end

        def in_def_class_methods?(node)
          defn = node.ancestors.find(&:def_type?)
          return unless defn

          mod = defn.ancestors.find do |ancestor|
            %i[class module].include?(ancestor.type)
          end
          return unless mod

          class_methods_module?(mod)
        end

        def in_def_module_function?(node)
          defn = node.ancestors.find(&:def_type?)
          return unless defn

          defn.left_siblings.any? { |sibling| module_function_bare_access_modifier?(sibling) } ||
            defn.right_siblings.any? { |sibling| module_function_for?(sibling, defn.method_name) }
        end

        def singleton_method_definition?(node)
          node.ancestors.any? do |ancestor|
            next unless ancestor.children.first.is_a? AST::SendNode

            ancestor.children.first.command? :define_singleton_method
          end
        end

        def method_definition?(node)
          node.ancestors.any? do |ancestor|
            next unless ancestor.children.first.is_a? AST::SendNode

            ancestor.children.first.command? :define_method
          end
        end

        def synchronized?(node)
          node.ancestors.find do |ancestor|
            next unless ancestor.block_type?

            s = ancestor.children.first
            s.send_type? && s.children.last == :synchronize
          end
        end

        def instance_variable_call?(node)
          instance_variable_set_call?(node) || instance_variable_get_call?(node)
        end

        def module_function_bare_access_modifier?(node)
          return false unless node

          node.send_type? && node.bare_access_modifier? && node.method?(:module_function)
        end

        def match_name?(arg_name, method_name)
          arg_name.to_sym == method_name.to_sym
        end

        def_node_matcher :class_methods_module?, <<~PATTERN
          (module (const _ :ClassMethods) ...)
        PATTERN

        def_node_matcher :module_function_for?, <<~PATTERN
          (send nil? {:module_function} ({sym str} #match_name?(%1)))
        PATTERN
      end
    end
  end
end
