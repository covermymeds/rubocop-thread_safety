# encoding: utf-8
# frozen_string_literal: true

module RuboCop
  module Cop
    module ThreadSafety
      class ClassAndModuleAttributes < Cop
        MSG = 'Avoid class and module attributes.'.freeze

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
