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

      ForInMatcher = AST::Matcher.new do
        [:while,
          [:has_next2, capture(:object_reg), capture(:index_reg)],
          [:begin,
            [:set_local, capture(:value_reg),
              [:coerce, capture(:value_type),
                [:next_value,
                  [:get_local, backref(:object_reg)],
                  [:get_local, backref(:index_reg)]]]],
            capture_rest(:body)]]
      end

      ForInIndexMatcher = AST::Matcher.new do
        [:set_local, backref(:index_reg), [:integer, 0]]
      end

      ForInObjectMatcher = AST::Matcher.new do
        [:set_local, backref(:object_reg),
          [:coerce_a,
            capture(:root)]]
      end

      def on_while(node)
        if captures = ForInMatcher.match(node)
          parent = node.parent

          index_node = object_node = nil

          loop_index = parent.children.index(node)
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
          object_node.update(:remove)

          node.update(:for_in, [
            captures[:value_reg],
            captures[:value_type],
            captures[:object_reg],
            AST::Node.new(:begin, captures[:body])
          ])
        end
      end
    end
  end
end