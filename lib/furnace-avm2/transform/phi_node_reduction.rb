module Furnace::AVM2
  module Transform
    module PhiNodeReduction
      def reduce_phi_nodes(cfg, root, target_id, supplementary_id)
        worklist = Set[ root ]
        visited  = Set[]

        while worklist.any?
          block = worklist.first
          worklist.delete block
          visited.add block

          gets = block.metadata.gets_map[target_id]
          gets.each do |get|
            if get.children.include? supplementary_id
              block.metadata.remove_get target_id
            end
          end

          block.targets.each do |target|
            if target.metadata.live.include? target_id
              worklist.add target unless visited.include? target
            end
          end
        end
      end
    end
  end
end