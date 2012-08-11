module Furnace::AVM2
  module Transform
    class FoldTernaryOperators
      include PhiNodeReduction

      def transform(cfg)
        changed = false

        cfg.nodes.each do |node|
          node_changed = false

          # Find a phi node.

          gets = node.metadata.gets_map.values.
                          map(&:to_a).flatten.uniq

          gets.select do |get|
            get.children.count > 1
          end.each do |phi|
            # Find two sources with the same single source.

            # id => source
            sources = Hash[
              phi.children.map do |id|
                [ id, node.sources.find { |source| source.metadata.sets.include?(id) } ]
              end.select do |id, source|
                source && source.sources.count == 1
              end
            ]

            left = right = shared = nil

            left = sources.values.find do |left_source|
              right = sources.values.find do |right_source|
                next if left_source == right_source

                left_source.sources.first == right_source.sources.first
              end
            end

            unless left
              next
            end

            shared = left.sources.first

            # Run sanity checks: each source should only set its
            # respective id; their shared source should have branch_if cti.

            unless left.metadata.sets.count == 1 &&
                      left.insns.count == 1 &&
                      right.metadata.sets.count == 1 &&
                      right.insns.count == 1 &&
                      shared.cti.type == :branch_if
              next
            end

            # Merge.

            left_id,  right_id  = left.metadata.sets.first,
                                  right.metadata.sets.first
            left_val, right_val = left.metadata.set_map[left_id],
                                  right.metadata.set_map[right_id]
            left_val, right_val = left_val.children.last,
                                  right_val.children.last

            compare_to, condition = shared.cti.children

            if compare_to
              left_val, right_val = right_val, left_val
            end

            shared.cti.update(:s, [
              left_id,
              AST::Node.new(:ternary, [
                condition,
                left_val, right_val
              ])
            ])

            shared.metadata.merge! left.metadata
            shared.metadata.merge! right.metadata

            shared.metadata.remove_set right_id
            node.metadata.remove_get right_id

            shared.metadata.set_map[left_id] = shared.cti
            shared.cti = nil

            shared.target_labels = [ node.label ]

            cfg.nodes.delete left
            cfg.nodes.delete right
            cfg.flush

            reduce_phi_nodes(cfg, shared, right_id, left_id)

            changed = node_changed = true
          end

          redo if node_changed
        end

        cfg if changed
      end
    end
  end
end