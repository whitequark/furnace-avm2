module Furnace::AVM2
  module Transform
    class DataflowInvariantCodeMotion
      def transform(cfg)
        worklist = Set[cfg.entry]
        visited  = Set[]

        any_changed = false

        while worklist.any?
          block = worklist.first
          worklist.delete block
          visited.add block

          changed = false

          #puts " =============== #{block.label}"

          block_meta = block.metadata
          block_meta.sets.each do |id|
            src_node = block_meta.set_map[id]

            targets = ([ block ] + block.targets).select do |target|
              target.metadata.gets.include? id
            end

            if !src_node.nil? && targets.one?
              target = targets.first
              target_meta = target.metadata

              #p target_meta[:gets_map]

              if target_meta.gets_map[id].one?
                dst_node  = target_meta.gets_map[id].first
                dst_upper = target_meta.gets_upper[dst_node]

                #p src_node, dst_node, dst_upper

                do_move = false

                if target == block
                  do_move = can_move_to?(src_node, target, dst_upper)
                else
                  do_move = can_move_to?(src_node, block,  nil) &&
                            can_move_to?(src_node, target, dst_upper)
                end

                if do_move
                  block.insns.delete src_node

                  block_meta.sets.delete id
                  block_meta.set_map.delete id

                  value = src_node.children.last
                  dst_node.update(value.type, value.children, value.metadata)

                  [ :read_barrier, :write_barrier ].each do |key|
                    dst_upper.metadata[key].merge src_node.metadata[key]
                  end

                  target_meta.gets.delete id
                  target_meta.gets_map.delete id
                  target_meta.gets_upper.delete dst_node

                  changed = true
                end
              end
            elsif targets.empty?
              if src_node.nil? || src_node.metadata[:write_barrier].empty?
                block.insns.delete src_node

                block_meta.sets.delete id
                block_meta.set_map.delete id

                changed = true
              end
            end
          end

          if changed
            worklist.add block
            any_changed = true
          end

          block.targets.each do |target|
            worklist.add target unless visited.include? target
          end
        end

        if any_changed
          cfg
        end
      end

      EMPTY_SET = Set[]

      def can_move_to?(src_node, block, dst_node)
        if start_index = block.insns.index(src_node)
          start_index += 1
        else
          start_index = 0
        end

        stop_index  = block.insns.index(dst_node) || block.insns.length

        wbar, rbar = src_node.metadata.values_at(:write_barrier, :read_barrier)

        block.insns[start_index...stop_index].each do |elem|
          elem_wbar, elem_rbar = elem.metadata.values_at(:write_barrier, :read_barrier)

          if (elem_wbar & wbar).any? ||
             (elem_wbar & rbar).any? ||
             (elem_rbar & wbar).any?
            return false
          end
        end

        true
      end
    end
  end
end