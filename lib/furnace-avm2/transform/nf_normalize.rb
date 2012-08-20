module Furnace::AVM2
  module Transform
    class NFNormalize
      include AST::Visitor

      def initialize(options={})
        @method = options[:method]
      end

      def transform(nf)
        @nf = nf

        visit @nf

        @nf
      end

      def on_any(node)
        node.metadata.delete :read_barrier
        node.metadata.delete :write_barrier
      end

      def on_s(node)
        index, value = node.children
        node.update(:set, [
          AST::Node.new(:local, [ -index ]), value
        ])
      end

      def on_r(node)
        if node.children.one?
          index, = node.children
          if index.is_a? Symbol
            node.update(:get, [
              AST::Node.new(:special, [ index ])
            ])
          else
            node.update(:get, [
              AST::Node.new(:local, [ -index ])
            ])
          end
        else
          node.update(:phi, node.children)
        end
      end

      def local_to_node(index)
        case index
        when 0
          AST::Node.new(:this)
        when 1..@method.param_count
          AST::Node.new(:param, [ index - 1 ])
        else
          AST::Node.new(:local, [ index - 1 - @method.param_count ])
        end
      end

      def on_get_local(node)
        index, = node.children

        case index
        when 0
          node.update(:this, [])
        else
          node.update(:get, [
            local_to_node(index)
          ])
        end
      end

      def on_set_local(node)
        index, value = node.children

        case index
        when 0
          raise "cannot setlocal 0"
        else
          node.update(:set, [
            local_to_node(index), value
          ])
        end
      end

      XREMENT_LOCAL_MAP = {
        :post_increment_local => :post_increment,
        :pre_increment_local  => :pre_increment,
        :post_decrement_local => :post_decrement,
        :pre_decrement_local  => :pre_decrement,
        :inc_local            => :post_increment,
        :dec_local            => :post_decrement,
      }

      def on_xrement_local(node)
        index, = node.children
        node.update(XREMENT_LOCAL_MAP[node.type],
          [ local_to_node(index) ])
      end

      XREMENT_LOCAL_MAP.each do |source, |
        alias_method :"on_#{source}", :on_xrement_local
      end

      def on_has_next2(node)
        left, right = node.children
        node.update(:has_next2,
          [ local_to_node(left), local_to_node(right) ])
      end

      ExpandedForInMatcher = AST::Matcher.new do
        [:if, [:has_next2, skip], skip]
      end

      # Loops can get expanded, but conditionals would never contain
      # has-next2.
      def do_if(node, parent)
        if ExpandedForInMatcher.match node
          condition, body, rest = node.children

          body.children << AST::Node.new(:break)

          loop = AST::Node.new(:while, [ condition, body ])
          do_while(loop, parent, node)

          if rest
            [ loop ] + rest.children
          else
            [ loop ]
          end
        else
          node
        end
      end

      ForInMatcher = AST::Matcher.new do
        [:while,
          [:has_next2, capture(:object_reg), capture(:index_reg)],
          [:begin,
            [ either_multi[
                [ :set, capture(:value_reg) ],
                [ :set_slot, capture(:value_reg), [:get_scope_object, any] ],
              ],
              [ either[:coerce, :convert], capture(:value_type),
                [ capture(:iterator),
                  [:get, backref(:object_reg)],
                  [:get, backref(:index_reg)]]]],
            capture_rest(:body)]]
      end

      ForInIndexMatcher = AST::Matcher.new do
        [:set, backref(:index_reg), [:integer, 0]]
      end

      ForInObjectMatcher = AST::Matcher.new do
        [:set, backref(:object_reg),
          [:coerce, :any,
            capture(:root)]]
      end

      def do_while(node, parent, enclosure=node)
        *whatever, code = node.children

        if captures = ForInMatcher.match(node)
          case captures[:iterator]
          when :next_name
            type = :for_in
          when :next_value
            type = :for_each_in
          else
            return
          end

          index_node = object_node = nil

          loop_index = parent.children.index(enclosure)
          parent.children[0..loop_index].reverse_each do |parent_node|
            if ForInIndexMatcher.match(parent_node, captures)
              index_node  = parent_node
            elsif ForInObjectMatcher.match(parent_node, captures)
              object_node = parent_node
            end

            break if index_node && object_node
          end

          return unless index_node && object_node

          index_node.update(:remove)
          object_node.update(:remove) if type != :for_each_in

          node.update(type, [
            captures[:value_reg],
            captures[:value_type],
            captures[:object_reg],
            AST::Node.new(:begin, captures[:body])
          ])
        end

        node
      end

      def on_begin(node)
        # Fix for-in loops.
        node.children.map! do |child|
          if child.type == :if
            do_if(child, node)
          elsif child.type == :while
            do_while(child, node)
          else
            child
          end
        end
        node.children.flatten!

        node.children.reject! do |child|
          child.type == :remove
        end

        # Fold (with)'s
        with_begin = node.children.index do |child|
          child.type == :push_with
        end
        with_end = nil

        if with_begin
          nesting = 0
          node.children[with_begin..-1].each_with_index do |child, index|
            if child.type == :push_with || child.type == :push_scope
              nesting += 1
            elsif child.type == :pop_scope
              nesting -= 1
              if nesting == 0
                with_end = with_begin + index
                break
              end
            end
          end

          if nesting == 0
            with_scope,  = node.children[with_begin].children
            with_content = node.children.slice (with_begin + 1)..(with_end - 1)

            with_node = AST::Node.new(:with, [
              with_scope,
              AST::Node.new(:begin,
                with_content
              )
            ])

            node.children.slice! with_begin..with_end
            node.children.insert with_begin, with_node
          end
        end

        # Remove obviously dead code
        first_ctn = node.children.index do |child|
          [:return, :break, :continue, :throw].include? child.type
        end
        return unless first_ctn

        node.children.slice! (first_ctn + 1)..-1
      end

      OptimizedSwitchSeed = AST::Matcher.new do
        [:ternary,
          [:===, capture(:case_value),
            [:get, capture(:local_index)]],
          [:integer, capture(:case_index)],
          capture(:nested)]
      end

      OptimizedSwitchNested = AST::Matcher.new do
        either[
          [:ternary,
            [:===, capture(:case_value),
              [:get, backref(:local_index)]],
            [:integer, capture(:case_index)],
            capture(:nested)],
          [:integer, capture(:default_index)]
        ]
      end

      NumericCase = AST::Matcher.new do
        [:case, [:integer, capture(:index)]]
      end

      def on_switch(node)
        condition, body = node.children

        if captures = OptimizedSwitchSeed.match(condition)
          mapping = { captures[:case_index] => captures[:case_value] }
          while captures = OptimizedSwitchNested.match(captures[:nested], captures)
            break if captures[:default_index]
            mapping[captures[:case_index]] = captures[:case_value]
          end

          return if captures.nil?

          case_mapping = {}

          body.children.each do |child|
            if case_captures = NumericCase.match(child)
              case_index = case_captures[:index]
              if captures[:default_index] == case_index
                case_mapping[child] = nil
              elsif mapping.has_key?(case_index)
                case_mapping[child] = mapping[case_index]
              else
                # fallback
                return
              end
            end
          end

          # At this point, we are sure that this switch can be transformed.

          node.children[0] = AST::Node.new(:get, [ captures[:local_index] ])

          case_mapping.each do |child, value|
            if value.nil?
              body.children.delete child
            else
              child.children[0] = value
            end
          end
        end
      end
    end
  end
end