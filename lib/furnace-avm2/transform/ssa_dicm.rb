module Furnace::AVM2
  module Transform
    class SSADataflowInvariantCodeMotion
      def transform(cfg, info)
        worklist = Set[cfg.entry]
        visited  = Set[]

        while worklist.any?
          block = worklist.first
          worklist.delete block
          visited.add block

          changed = false

          block_info = info[block]
          block_info[:sets].each do |id|
            src_node  = block_info[:set_map][id]

            targets = ([ block ] + block.targets).select do |target|
              info[target][:gets].include? id
            end

            if targets.one?
              target = targets.first
              target_info = info[target]

              if target_info[:gets_map][id].one?
                dst_node  = target_info[:gets_map][id].first
                dst_upper = target_info[:gets_upper][dst_node]

                do_move = false

                if target == block
                  do_move = can_move_to?(src_node, target, dst_upper)
                else
                  do_move = can_move_to?(src_node, block,  nil) &&
                            can_move_to?(src_node, target, dst_upper)
                end

                if do_move
                  block.insns.delete src_node

                  block_info[:sets].delete id
                  block_info[:set_map].delete id

                  value = src_node.children.last
                  dst_node.update(value.type, value.children, value.metadata)

                  [ :read_barrier, :write_barrier ].each do |key|
                    dst_upper.metadata[key].merge src_node.metadata[key]
                  end

                  target_info[:gets].delete id
                  target_info[:gets_map].delete id
                  target_info[:gets_upper].delete dst_node

                  changed = true
                end
              end
            elsif targets.empty?
              if src_node.metadata[:read_barrier].empty? &&
                 src_node.metadata[:write_barrier].empty?
                block.insns.delete src_node

                block_info[:sets].delete id
                block_info[:set_map].delete id

                changed = true
              end
            end
          end

          worklist.add block if changed

          block.targets.each do |target|
            worklist.add target unless visited.include? target
          end
        end

        cfg.merge_redundant!

        [ cfg, info ]
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
          next if elem.type == :_info #NBNB

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