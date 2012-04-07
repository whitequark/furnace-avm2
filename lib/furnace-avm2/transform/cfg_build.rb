module Furnace::AVM2
  module Transform
    class CFGBuild
      include AST::Visitor

      def transform(ast, method)
        @ast = ast
        visit @ast

        @cfg = CFG::Graph.new

        @pending_label = nil
        @pending_queue = []

        @jumps = []

        @ast.children.each_with_index do |node, index|
          @pending_label ||= node.metadata[:label]
          @pending_queue << node if ![:nop, :jump].include? node.type

          next_node  = @ast.children[index + 1]
          next_label = next_node.metadata[:label] if next_node

          case node.type
          when :return_value, :return_void
            cutoff(node, [nil])

          when :jump
            @jumps << node.children[0]
            cutoff(nil, [node.children.delete_at(0)])

          when :jump_if
            @jumps << node.children[1]
            cutoff(node, [node.children.delete_at(1), next_label])

          else
            if @jumps.include? next_label
              cutoff(nil, [next_label])
            end
          end
        end

        exit_node = CFG::Node.new(@cfg)
        @cfg.nodes.add exit_node
        @cfg.exit = exit_node

        @cfg.eliminate_unreachable!
        @cfg.merge_redundant!

        [ @cfg, method ]
      end

      # propagate labels
      def on_any(node)
        return if node == @ast

        label = nil

        node.children.each do |child|
          if child.is_a?(AST::Node) && child.metadata[:label]
            if label.nil? || child.metadata[:label] < label
              label = child.metadata[:label]
            end

            child.metadata.delete :label
          end
        end

        node.metadata[:label] = label if label
      end

      def cutoff(cfi, targets)
        node = CFG::Node.new(@cfg, @pending_label, @pending_queue, cfi, targets)

        if @cfg.nodes.empty?
          @cfg.entry = node
        end

        @cfg.nodes.add node

        @pending_label = nil
        @pending_queue = []
      end
    end
  end
end