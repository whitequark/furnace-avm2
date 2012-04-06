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
        :eq       => [false, 2, :==],
        :ne       => [true,  2, :==],
        :ge       => [false, 2, :>=],
        :nge      => [true,  2, :>=],
        :gt       => [false, 2, :>],
        :ngt      => [true,  2, :>],
        :le       => [false, 2, :<=],
        :nle      => [true,  2, :<=],
        :lt       => [false, 2, :<],
        :nlt      => [true,  2, :<],
        :stricteq => [false, 2, :===],
        :strictne => [true,  2, :===],
        :true     => [false, nil, :expand],
        :false    => [true,  nil, :expand],
      }
      IF_MAPPING.each do |cond, (reverse, first_arg, comp)|
        define_method :"on_if_#{cond}" do |node|
          node.update(comp)
          node.parent.children[0] = !node.parent.children[0] if reverse
          if first_arg
            node.parent.children.concat node.children.slice!(first_arg..-1)
          end
        end
      end

      # (&& (coerce-b ...) (coerce-b ...)) -> (&& ... ...)
      def fix_boolean(node)
        node.children.map! do |child|
          if child.type == :coerce_b
            child.children.first
          else
            child
          end
        end
      end
      alias :on_and :fix_boolean
      alias :on_or  :fix_boolean

      # (ternary-if true  a x y) -> (ternary-if a x y)
      # (ternary-if false a x y) -> (ternary-if a y x)
      def on_ternary_if(node)
        comp, cond, if_true, if_false = node.children
        if comp
          node.children.replace([ cond, if_true, if_false ])
        else
          node.children.replace([ cond, if_false, if_true ])
        end

        node.children.map! do |child|
          if child.type =~ /^(convert|coerce)/
            child.children.first
          else
            child
          end
        end
      end

      def remove_node(node)
        node.update(:remove)
      end
      alias :on_jump_target :remove_node
      alias :on_nop         :remove_node
      alias :on_debug       :remove_node
      alias :on_debug_file  :remove_node
      alias :on_debug_line  :remove_node
    end
  end
end