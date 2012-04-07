module Furnace::AVM2
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
          AST::Node.new(:nop, [], node.metadata)
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
        :eq        => [false, :==],
        :ne        => [true,  :==],
        :ge        => [false, :>=],
        :nge       => [true,  :>=],
        :gt        => [false, :>],
        :ngt       => [true,  :>],
        :le        => [false, :<=],
        :nle       => [true,  :<=],
        :lt        => [false, :<],
        :nlt       => [true,  :<],
        :strict_eq => [false, :===],
        :strict_ne => [true,  :===],
        :true      => [false, :expand],
        :false     => [true,  :expand]
      }
      IF_MAPPING.each do |cond, (reverse, comp)|
        define_method :"on_if_#{cond}" do |node|
          node.update(comp)
          node.parent.children[0] = !node.parent.children[0] if reverse

          if node.parent.type == :ternary_if && comp == :expand
            node.parent.update(:ternary_if_boolean)
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

      # (&& (coerce-b ...) (coerce-b ...)) -> (&& ... ...)
      def fix_boolean(node)
        node.children.map! do |child|
          if child.is_a?(AST::Node) &&
                child.type == :coerce_b
            child.children.first
          else
            child
          end
        end
      end
      alias :on_and     :fix_boolean
      alias :on_or      :fix_boolean
      alias :on_jump_if :fix_boolean

      def replace_with_nop(node)
        node.update(:nop)
      end
      alias :on_label       :replace_with_nop
      alias :on_debug       :replace_with_nop
      alias :on_debug_file  :replace_with_nop
      alias :on_debug_line  :replace_with_nop
    end
  end
end