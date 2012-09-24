module Furnace::AVM2
  module Transform
    class ExpandUnreferencedSets
      def transform(cfg)
        cfg.nodes.each do |block|
          block.metadata.sets.each do |id|
            if !block.metadata.gets.include?(id) &&
                  block.targets.none? { |target|
                    target.metadata.live.include?(id)
                  }
              set = block.metadata.set_map[id]

              if set.metadata[:write_barrier].empty?
                block.insns.delete set
                block.metadata.unregister_upper set
              else
                _, set_value = set.children
                set.update(set_value.type,
                    set_value.children)
              end

              block.metadata.remove_set id
            end
          end
        end

        cfg
      end
    end
  end
end