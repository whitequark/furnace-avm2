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

      COERCE_MAP = {
        :coerce_a => :any,
        :coerce_b => :bool,
        :coerce_s => :string,
      }

      def on_coerce_imm(node)
        expr, = node.children
        node.update(:coerce, [
          COERCE_MAP[node.type],
          expr
        ])
      end
      alias :on_coerce_a :on_coerce_imm
      alias :on_coerce_b :on_coerce_imm
      alias :on_coerce_s :on_coerce_imm

      CONVERT_MAP = {
        :convert_i => :integer,
        :convert_u => :unsigned,
        :convert_d => :double,
        :convert_s => :string,
        :convert_o => :object,
      }

      def on_convert_imm(node)
        expr, = node.children
        node.update(:convert, [
          CONVERT_MAP[node.type],
          expr
        ])
      end
      alias :on_convert_i :on_convert_imm
      alias :on_convert_u :on_convert_imm
      alias :on_convert_d :on_convert_imm
      alias :on_convert_s :on_convert_imm
      alias :on_convert_o :on_convert_imm

      ForInMatcher = AST::Matcher.new do
        [:while,
          [:has_next2, capture(:object_reg), capture(:index_reg)],
          [:begin,
            [:set_local, capture(:value_reg),
              [either[:coerce, :convert], capture(:value_type),
                [capture(:iterator),
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

      def on_while(node)
        if captures = ForInMatcher.match(node)
          parent = node.parent

          case captures[:iterator]
          when :next_name
            type = :for_in
          when :next_value
            type = :for_each_in
          else
            return
          end

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

          if SuperfluousContinueMatcher.match captures[:body].last
            captures[:body].slice! -1
          end

          node.update(type, [
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