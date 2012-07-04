module Furnace::AVM2
  module Transform
    class NFNormalize
      include AST::Visitor

      def transform(nf)
        @nf = nf.normalize_hierarchy!

        remove_useless_return
        visit @nf

        @nf
      end

      def remove_useless_return
        if @nf.children.last.type == :return_void
          @nf.children.slice! -1
        end
      end

      def on_nop(node)
        node.update(:remove)
      end

      LocalIncDecMatcher = AST::Matcher.new do
        [ either_multi[
            [:set_slot,  capture(:index), capture(:scope)],
            [:set_local, capture(:index)],
          ],
          either[
            [:convert, any,
              capture(:inner)],
            [:coerce, :any,
              capture(:inner)],
            capture(:inner)
          ]
        ]
      end

      LocalIncDecInnerMatcher = AST::Matcher.new do
        [capture(:operator),
          either[
            [:convert, any,
              capture(:getter)],
            capture(:getter),
          ]
        ]
      end

      LocalIncDecGetterMatcher = AST::Matcher.new do
        either[
          [:get_slot,  backref(:index), backref(:scope)],
          [:get_local, backref(:index)],
        ]
      end

      IncDecOperators = [
        :pre_increment, :post_increment,
        :pre_decrement, :post_decrement
      ]

      def on_set_local(node)
        captures = {}
        if LocalIncDecMatcher.match(node, captures) &&
              LocalIncDecInnerMatcher.match(captures[:inner], captures) &&
              IncDecOperators.include?(captures[:operator])
          if captures[:getter].is_a?(AST::Node) &&
              LocalIncDecGetterMatcher.match(captures[:getter], captures)
            if captures[:scope]
              node.update(:"#{captures[:operator]}_slot", [ captures[:index], captures[:scope] ])
            else
              node.update(:"#{captures[:operator]}_local", [ captures[:index] ])
            end
          else
            node.update(:add, [
              AST::Node.new(:set_local, [
                captures[:index],
                captures[:getter]
              ]),
              AST::Node.new(:integer, [ 1 ])
            ])
          end
        end
      end
      alias :on_set_slot :on_set_local

      ExpandedForInMatcher = AST::Matcher.new do
        [:if, [:has_next2, skip], skip]
      end

      # Loops can get expanded, but conditionals would never contain
      # has-next2.
      def on_if(node)
        if ExpandedForInMatcher.match node
          condition, body, rest = node.children

          body.children << AST::Node.new(:break)

          loop = AST::Node.new(:while, [ condition, body ])
          on_while(loop, node.parent, node)

          if rest
            node.update(:expand, [ loop ] + rest.children)
          else
            node.update(:expand, [ loop ])
          end
        end
      end

      ForInMatcher = AST::Matcher.new do
        [:while,
          [:has_next2, capture(:object_reg), capture(:index_reg)],
          [:begin,
            [ either_multi[
                [ :set_local, capture(:value_reg) ],
                [ :set_slot, capture(:value_reg), [:get_scope_object, 1] ],
              ],
              [ either[:coerce, :convert], capture(:value_type),
                [ capture(:iterator),
                  [:get_local, backref(:object_reg)],
                  [:get_local, backref(:index_reg)]]]],
            capture_rest(:body)]]
      end

      ForInIndexMatcher = AST::Matcher.new do
        [:set_local, backref(:index_reg), [:integer, 0]]
      end

      ForInObjectMatcher = AST::Matcher.new do
        [:set_local, backref(:object_reg),
          [:coerce, :any,
            capture(:root)]]
      end

      SuperfluousContinueMatcher = AST::Matcher.new do
        [:continue]
      end

      def on_while(node, parent=node.parent, enclosure=node)
        *whatever, code = node.children
        if SuperfluousContinueMatcher.match code.children.last
          code.children.slice! -1
        end

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
      end

      def on_begin(node)
        first_ctn = node.children.find_index do |child|
          [:return_void, :return_value, :break, :continue, :throw].include? child.type
        end
        return unless first_ctn

        node.children.slice! (first_ctn + 1)..-1
      end

      OptimizedSwitchSeed = AST::Matcher.new do
        [:ternary,
          [:===, capture(:case_value),
            [:get_local, capture(:local_index)]],
          [:integer, capture(:case_index)],
          capture(:nested)]
      end

      OptimizedSwitchNested = AST::Matcher.new do
        either[
          [:ternary,
            [:===, capture(:case_value),
              [:get_local, backref(:local_index)]],
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

          node.children[0] = AST::Node.new(:get_local, [ captures[:local_index] ])

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