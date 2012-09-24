module Furnace::AVM2
  module Transform
    class FoldInvariantPhiNodes
      def transform(cfg)
        set_aliases = Hash.new { Set[] }
        set_origins = {}

        cfg.nodes.each do |block|
          block_aliases = Set[]

          block.metadata.sets.each do |set|
            set_origins[set] = block
            set_aliases[set] = block_aliases
            block_aliases.add set
          end
        end

        updated = false

        cfg.nodes.each do |block|
          p "========== BLOCK #{block.label}"
          block.metadata.gets_map.each do |get, nodes|
            nodes.each do |node|
              p "GET #{get} #{node}"

              redundant = set_aliases[get] & node.children
              origin    = set_origins[get]

              if origin == block
                preceding_sets = redundant.select { |id|
                  origin.insns.index(origin.metadata.set_map[id]) <
                      origin.insns.index(origin.metadata.gets_upper[node])
                }
                p "SAME ORIGIN", preceding_sets
              else
                preceding_sets = redundant
                p "OTHER ORIGIN", preceding_sets
              end

              next unless preceding_sets.count > 1

              keep = preceding_sets.max_by { |id|
                origin.insns.index(origin.metadata.set_map[id])
              }

              preceding_sets.delete keep
              p "KEEP #{keep} REMOVE #{preceding_sets.to_a}"

              node.children -= preceding_sets.to_a

              preceding_sets.each do |id|
                block.metadata.gets_map[id].delete node
                if block.metadata.gets_map[id].empty?
                  block.metadata.gets.delete id
                  block.metadata.gets_map.delete id
                end
              end

              updated = true
            end
          end
        end

        cfg if updated
      end
    end
  end
end