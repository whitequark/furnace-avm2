module AVM2
  module Transform
    class ASTNormalize
      include AST::Visitor

      def transform(ast, method)
        visit ast

        [ ast, method ]
      end

      # (pop x) -> (jump-target) x
      def on_pop(node)
        child = node.children.first

        node.update(:expand, [
          child,
          AST::Node.new(:jump_target, [], node.metadata)
        ], nil)
      end

      # (call-property-void *) -> (call-property *)
      def on_call_property_void(node)
        node.update(:call_property)
      end

      # (call-super-void *) -> (call-super *)
      def on_call_super_void(node)
        node.update(:call_super)
      end

      # (if-* a b) -> (*' a b)
      IF_MAPPING = {
        :eq  => [false, :equals],
        :nge => [true,  :greaterequals],
      }
      IF_MAPPING.each do |cond, (reverse, comp)|
        define_method :"on_if_#{cond}" do |node|
          node.update(comp)
          node.parent.children[0] = !node.parent.children[0] if reverse
        end
      end

      # TEMPORARY: (jump-target) -> x
      def on_jump_target(node)
        node.update(:remove)
      end
    end
  end
end