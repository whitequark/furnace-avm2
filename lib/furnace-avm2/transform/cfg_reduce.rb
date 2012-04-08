module Furnace::AVM2
  module Transform
    class CFGReduce
      def transform(cfg)
        @cfg   = cfg
        @loops = @cfg.identify_loops

        @visited = Set.new

        ast, = extended_block(@cfg.entry)

        ast
      end

      def extended_block(block, upper_root=nil, upper_merge=nil)
        nodes = []

        while block
          break if upper_merge == block

          if @visited.include? block
            raise "failsafe: block already visited"
          elsif block != @cfg.exit
            @visited.add block
          end

          block.insns.each do |insn|
            next if insn == block.cfi
            nodes << insn
          end

          if block.cfi
            if @loops.include?(block)
              raise "loop"
            else
              # this is a conditional
              left_root, right_root = block.targets
              if block.cfi.children[0] == false
                left_root, right_root = right_root, left_root
              end

              merge = find_merge_point(left_root, right_root)

              left_seq  = extended_block(left_root,  block, merge)
              right_seq = extended_block(right_root, block, merge)


              if left_seq.children.empty? && right_seq.children.any?
                if_node = AST::Node.new(:if, [
                  AST::Node.new(:!, [ block.cfi.children[1] ]),
                  right_seq
                ])
              else
                if right_seq.children.empty?
                  if_node = AST::Node.new(:if, [
                    block.cfi.children[1],
                    left_seq
                  ])
                else
                  if_node = AST::Node.new(:if, [
                    block.cfi.children[1],
                    left_seq,
                    right_seq
                  ])
                end
              end

              nodes << if_node

              block = merge
            end
          elsif block.targets.count == 1
            block = block.targets.first
          elsif block.targets.count == 0
            break
          else
            raise "targets > 1 and no cfi"
          end
        end

        AST::Node.new(:begin, nodes)
      end

      def find_merge_point(left, right)
        left_visited = bfs(left)

        bfs(right) do |node|
          if left_visited.include? node
            return node
          end
        end

        raise "IMPOSIBRU: no merge point"
      end

      # Breadth-first search
      def bfs(root)
        visited, queue = Set.new, [root]

        while queue.any?
          node = queue.shift
          visited.add node

          yield node if block_given?

          node.targets.each do |child|
            next if visited.include? child
            queue.push child
          end
        end

        visited
      end
    end
  end
end