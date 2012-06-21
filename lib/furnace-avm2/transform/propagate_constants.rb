module Furnace::AVM2
  module Transform
    # This pass does NOT do proper DFA. It is here only to propagate
    # find-property-strict calls down the AST.
    class PropagateConstants
      include AST::Visitor

      class Replacer
        include AST::Visitor

        def initialize(local_var, value)
          @local_var, @value = local_var, value
        end

        def replace_in(nodes)
          @nodes = nodes
          @graceful_shutdown = true

          catch(:stop) {
            @nodes.each do |node|
              visit node
            end
          }

          @graceful_shutdown
        end

        def on_set_local(node)
          index, value = node.children
          if index == @local_var
            @graceful_shutdown = @nodes.include?(node)
            throw :stop
          end
        end

        def on_get_local(node)
          index, = node.children
          if index == @local_var
            node.update(@value.type, @value.children.dup, @value.metadata)
          end
        end
      end

      def transform(ast, *stuff)
        visit ast

        [ ast, *stuff ]
      end

      def on_set_local(node)
        index, value = node.children
        if value.type == :find_property_strict
          block = node.parent
          nodes = block.children[(block.children.index(node) + 1)..-1]

          replacer = Replacer.new(index, value)
          if replacer.replace_in(nodes)
            node.update(:remove)
          end
        end
      end
    end
  end
end