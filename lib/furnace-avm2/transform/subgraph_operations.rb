module Furnace::AVM2
  module Transform
    module SubgraphOperations
      def walk_live_nodes(cfg, root, id)
        worklist = Set[ root ]
        visited  = Set[]

        while worklist.any?
          block = worklist.first
          worklist.delete block
          visited.add block

          yield block

          block.targets.each do |target|
            if target.metadata.live.include? id
              worklist.add target unless visited.include? target
            end
          end
        end
      end

      def reduce_phi_nodes(cfg, root, target_id, supplementary_id)
        walk_live_nodes(cfg, root, target_id) do |block|
          gets = block.metadata.gets_map[target_id]
          gets.each do |get|
            if get.children.include? supplementary_id
              block.metadata.remove_get target_id
            end
          end
        end
      end

      def replace_r_nodes(cfg, root, target_id, replacement)
        walk_live_nodes(cfg, root, target_id) do |block|
          gets = block.metadata.gets_map[target_id]
          gets.each do |get|
            get.update(replacement.type,
                replacement.children,
                replacement.metadata)
          end
        end
      end
    end
  end
end