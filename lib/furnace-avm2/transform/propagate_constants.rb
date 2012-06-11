module Furnace::AVM2
  module Transform
    # This pass does NOT do proper DFA. It is here only to propagate
    # find-property-strict calls down the AST.
    class PropagateConstants
      include AST::Visitor

      def transform(ast)
        @local_nonconst = Set.new
        @local_sets = {}
        @local_gets = Hash.new { |h,k| h[k] = [] }

        visit ast

        @local_sets.each do |index, set_node|
          *, value = set_node.children

          unless @local_nonconst.include? index
            @local_gets[index].each do |get_node|
              get_node.update(:find_property_strict,
                value.children.dup,
                get_node.metadata)
            end

            set_node.update(:nop, [])
          end
        end

        ast
      end

      def on_set_local(node)
        index, value = node.children
        if value.type == :find_property_strict
          if @local_sets.has_key?(index)
            @local_nonconst.add index
          else
            @local_sets[index] = node
          end
        end
      end

      def on_get_local(node)
        index, = node.children
        @local_gets[index].push node
      end
    end
  end
end