module Furnace::AVM2
  module Transform
    class ASTNormalize
      include AST::Visitor

      def initialize(options={})
        @options = options
      end

      def transform(ast, *stuff)
        visit ast

        [ ast, *stuff ]
      end

      # (if-* a b) -> (*' a b)
      IF_MAPPING = {
        :eq        => [false, :==],
        :ne        => [false, :!=],
        :ge        => [false, :>=],
        :nge       => [true,  :>=],
        :gt        => [false, :>],
        :ngt       => [true,  :>],
        :le        => [false, :<=],
        :nle       => [true,  :<=],
        :lt        => [false, :<],
        :nlt       => [true,  :<],
        :strict_eq => [false, :===],
        :strict_ne => [true,  :===], # Why? Because of (lookup-switch ...).
        :true      => [false, :expand],
        :false     => [true,  :expand]
      }

      def transform_conditional(node, comp, reverse)
        node.update(comp)
        node.parent.children[0] = !node.parent.children[0] if reverse
      end

      IF_MAPPING.each do |cond, (reverse, comp)|
        define_method :"on_if_#{cond}" do |node|
          if node.parent.type == :jump_if || comp != :expand
            # Parent is a conditional, or this is an explicit comparsion.
            transform_conditional(node, comp, reverse)
          elsif node.parent.type == :ternary_if && node.index == 1
            # Parent is a comparsion-less ternary operator, and this
            # node is in condition position.
            transform_conditional(node, comp, reverse)
            node.parent.update(:ternary_if_boolean)
          elsif node.children.count == 2
            # This is an implicit comparsion, and it is not located in
            # a condition position of a conditional or a ternary operator.
            # Turn it into a ternary operator as of itself.
            node.update(:ternary_if_boolean, [
              !comp, *node.children
            ])
            on_ternary_if_boolean(node)
          else
            transform_conditional(node, comp, reverse)
          end
        end
      end

      # (ternary-if * (op a b x y)) -> (ternary-if-boolean * (op a b) x y)
      def on_ternary_if(node)
        comparsion, op = node.children
        node.children.concat op.children.slice!(2..-1)

        on_ternary_if_boolean(node)
      end

      # (ternary-if-boolean true  (op a b) x y) -> (ternary (op a b) x y)
      # (ternary-if-boolean false (op a b) x y) -> (ternary (op a b) y x)
      def on_ternary_if_boolean(node)
        comparsion, condition, if_true, if_false = node.children
        if comparsion
          node.update(:ternary, [ condition, if_true, if_false ])
        else
          node.update(:ternary, [ condition, if_false, if_true ])
        end
      end
    end
  end
end