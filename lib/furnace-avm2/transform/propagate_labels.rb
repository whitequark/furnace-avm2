module Furnace::AVM2
  module Transform
    class PropagateLabels
      include AST::Visitor

      def transform(ast, body)
        visit ast      # propagate labels

        [ast, body]
      end

      def on_any(node)
        return if node.type == :root

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
    end
  end
end