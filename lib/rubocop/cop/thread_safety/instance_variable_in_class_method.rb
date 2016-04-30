# encoding: utf-8
# frozen_string_literal: true

module RuboCop
  module Cop
    module ThreadSafety
      class InstanceVariableInClassMethod < Cop
        MSG = 'Avoid instance variables in class methods.'.freeze

        def on_ivar(node)
          return unless in_defs?(node) || in_def_sclass?(node) || singleton_method_definition?(node)

          add_offense(node, :name, MSG)
        end
        alias on_ivasgn on_ivar

        private

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
            next unless ancestor.children.first.is_a? Node
            ancestor.children.first.command? :define_singleton_method
          end
        end
      end
    end
  end
end
