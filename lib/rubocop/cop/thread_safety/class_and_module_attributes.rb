# encoding: utf-8
# frozen_string_literal: true

module RuboCop
  module Cop
    module ThreadSafety
      # Avoid mutating class and module attributes.
      #
      # They are implemented by class variables, which are not thread-safe.
      #
      # @example
      #   # bad
      #   class User
      #     cattr_accessor :current_user
      #   end
      class ClassAndModuleAttributes < Cop
        MSG = 'Avoid mutating class and module attributes.'.freeze

        def_node_matcher :mattr?, <<-END
          (send nil
            {:mattr_writer :mattr_accessor :cattr_writer :cattr_accessor}
            ...)
        END

        def on_send(node)
          return unless mattr?(node)
          add_offense(node, :expression, format(MSG, node.source))
        end
      end
    end
  end
end
