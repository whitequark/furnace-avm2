module Furnace::AVM2
  module Transform
    class PropagateConstants
      include SubgraphOperations

      def transform(cfg)
        changed = false

        evaluator = Evaluator.new

        cfg.nodes.each do |block|
          block.metadata.sets.each do |id|
            set = block.metadata.set_map[id]
            _, set_value = set.children

            # TODO add options for folding complex constants
            if evaluator.immediate?(set_value) ||
                set_value.type == :this ||
                set_value.type == :find_property_strict

              replace_r_nodes(cfg, block, id, set_value) do |child_block|
                child_block.metadata.live.delete id
              end

              block.metadata.remove_set id
              block.insns.delete set

              changed = true
            end
          end
        end

        cfg
      end
    end
  end
end