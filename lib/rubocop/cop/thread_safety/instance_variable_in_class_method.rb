# encoding: utf-8
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
      class InstanceVariableInClassMethod < Cop
        MSG = 'Avoid instance variables in class methods.'.freeze

        def on_ivar(node)
          return unless class_method_definition?(node)
          return if synchronized?(node)

          add_offense(node, location: :name, message: MSG)
        end
        alias on_ivasgn on_ivar

        private

        def class_method_definition?(node)
          in_defs?(node) ||
            in_def_sclass?(node) ||
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

          defn && defn.ancestors.any? do |ancestor|
            ancestor.type == :sclass
          end
        end

        def singleton_method_definition?(node)
          node.ancestors.any? do |ancestor|
            next unless ancestor.children.first.is_a? AST::SendNode
            ancestor.children.first.command? :define_singleton_method
          end
        end

        def synchronized?(node)
          node.ancestors.find do |ancestor|
            next unless ancestor.block_type?
            s = ancestor.children.first
            s.send_type? && s.children.last == :synchronize
          end
        end
      end
    end
  end
end
