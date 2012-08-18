module Furnace::AVM2
  module Transform
    class FoldPassthroughAssignments
      def transform(cfg)
        cfg.nodes.each do |block|
          block.metadata.sets.each do |id|
            # All references should be contained in the same
            # block as the definition.
            if block.targets.any? { |t| t.metadata.live.include? id }
              next
            end

            # Every reference except the last one should be a direct
            # descendant of (set-local) node.
            sorted_nodes = block.metadata.gets_map[id].map do |node|
              [ node, block.metadata.gets_upper[node] ]
            end.sort_by do |node, upper|
              block.insns.index(upper)
            end

            unless sorted_nodes[0..-2].all? { |(node, upper)| can_fold_node?(node, upper) }
              next
            end

            # Fold the constructs.
            set_node = block.metadata.set_map[id]
            _, set_value = set_node.children
            sorted_nodes.reduce(set_value) do |prev, (node, upper)|
              node.update(prev.type, prev.children)
              upper
            end

            # Remove replaced nodes.
            block.insns.delete set_node
            sorted_nodes[0..-2].each do |node, upper|
              block.insns.delete upper
            end

            # Update metadata.
            block.metadata.remove_set id
            block.metadata.unregister_get id
          end
        end

        cfg
      end

      def can_fold_node?(r_node, upper)
        case upper.type
        when :set_local
          # Regular passthrough assignment.
          index, value = upper.children
          value == r_node
        when :push_scope
          # Used for matching catch scope reestablishment.
          value, = upper.children
          value == r_node
        else
          false
        end
      end
    end
  end
end