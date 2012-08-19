module Furnace::AVM2
  module Transform
    module SubgraphOperations
      def ssa_worklist(cfg)
        # Compose worklist, an ordered list of basic blocks.
        # General idea: for every block except loop heads, have each
        # source visited before this block. For loop heads, have
        # everything except blocks with back edges visited beforehand.

        dom      = cfg.dominators
        visited  = Set[ nil ]
        nodes    = Set[ cfg.entry ]
        worklist = []

        while nodes.any?
          applicable_nodes = nodes.select do |node|
            node.sources.reduce(true) do |result, source|
              result &&
                (visited.include?(source) ||
                dom[source].include?(node))
            end
          end

          if applicable_nodes.empty?
            raise "no applicable nodes"
          end

          nodes.subtract applicable_nodes
          visited.merge applicable_nodes

          worklist += applicable_nodes

          applicable_nodes.each do |node|
            node.targets.each do |target|
              nodes.add target unless visited.include? target
            end

            nodes.add node.exception unless visited.include? node.exception
          end
        end

        worklist
      end

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

              if block.metadata.gets_map[target_id].empty?
                block.metadata.live.delete target_id
              end
            end
          end

          yield if block_given?
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

          yield block if block_given?
        end
      end
    end
  end
end