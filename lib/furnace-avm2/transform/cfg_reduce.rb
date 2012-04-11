module Furnace::AVM2
  module Transform
    class CFGReduce
      def transform(cfg)
        @cfg   = cfg

        @dom   = @cfg.dominators
        @loops = @cfg.identify_loops

        @visited       = Set.new
        @loop_tails    = {}
        @loop_nonlocal = Set.new

        ast, = extended_block(@cfg.entry)

        ast
      end

      def extended_block(block, stopgap=nil, loop_stack=[])
        nodes = []

        while block
          if @loops.include?(block) && loop_stack.include?(block)
            # We have just arrived to loop head. Insert `continue'
            # and exit.
            check_nonlocal_loop(loop_stack, block) do |params|
              nodes << AST::Node.new(:continue, params)
            end
            break
          elsif @loop_tails.include?(block) &&
                    loop_stack.include?(@loop_tails[block])
            # We have just arrived to loop tail. Insert `break'
            # and exit.
            loop = @loop_tails[block]
            check_nonlocal_loop(loop_stack, loop) do |params|
              nodes << AST::Node.new(:break, params)
            end
            break
          elsif block == stopgap
            # We have just arrived to a merge point of `if'
            # contidional. Exit.
            break
          end

          if @visited.include? block
            raise "failsafe: block #{block.label} already visited"
          elsif block != @cfg.exit
            @visited.add block
          end

          block.insns.each do |insn|
            next if insn == block.cti
            nodes << insn
          end

          if block.cti
            if @loops.include?(block)
              # we're trapped in a strange loop
              reverse = !block.cti.children[0]
              in_root, out_root = block.targets

              # One of the branch targets should reside within
              # the loop.
              if !@loops[block].include?(in_root)
                in_root, out_root = out_root, in_root
                reverse = !reverse
              end

              # Mark the loop tail so we could detect `break' and
              # `continue' statements.
              @loop_tails[out_root] = block

              # If we reversed the roots or it was a (jump-if false),
              # then reverse the condition.
              expr = normalize_cti_expr(block, reverse)

              body = extended_block(in_root, nil, [ block, *loop_stack ])

              # [(label name)]
              # We first parse the body and then add the label before
              # the loop body if anything in the body requires that label
              # to be present.
              if @loop_nonlocal.include?(block)
                nodes << AST::Node.new(:label, [ loop_label(block) ])
              end

              # (while (condition)
              #   (body ...))
              nodes << AST::Node.new(:while, [
                expr,
                body
              ])

              block = out_root
            else
              # this is an `if', `break' or `continue'
              reverse = !block.cti.children[0]
              left_root, right_root = block.targets

              # (if (condition)
              #   (if-true ...)
              #  [(if-false ...)])
              # Note that you cannot reach expression if-true nor
              # expression if-false without evaluating condition.
              # Thus, to go inside the if body, a root has to be
              # completely dominated by this block--that is, does
              # not have edges coming to it even from other blocks
              # dominated by this block.

              # If the left root isn't dominated by block,
              # then it can't be `if' branch.
              if !completely_dominated?(left_root, block)
                left_root, right_root = right_root, left_root
                reverse = !reverse
              end

              # If the left root still isn't dominated by block,
              # then this is not a proper conditional.
              unless completely_dominated?(left_root, block)
                raise "not-well-formed if"
              end

              # If the right root is dominated by this block, which
              # means that we have an `else' part, and if the condition
              # is reversed, turn that back. This serves purely aesthetical
              # purposes and depends on behavior of ASC code generator.
              if completely_dominated?(right_root, block) && reverse
                left_root, right_root = right_root, left_root
                reverse = false
              end

              # If we reversed the roots or it was a (jump-if false),
              # then reverse the condition.
              expr = normalize_cti_expr(block, reverse)

              # Does this conditional have an `else' block?
              if completely_dominated?(right_root, block)
                # Yes. Find a merge point.
                merge = find_merge_point(block, left_root, right_root, loop_stack)

                # If the merge search did not yield a valid node, use
                # stopgap for the current block to avoid runaway code
                # synthesis.
                #
                # The stopgap block is actually an innermost block from
                # a stopgap block set implicitly represented by a set of
                # objects contained in arguments of recursive calls. As
                # the `if's are fully nested when well-formed, we can only
                # check for collision with innermost stopgap block.
                nodes << AST::Node.new(:if, [
                  expr,
                  extended_block(left_root,  merge || stopgap, loop_stack),
                  extended_block(right_root, merge || stopgap, loop_stack)
                ])

                block = merge
              else
                # No. The "right root" is actually post-if code.
                nodes << AST::Node.new(:if, [
                  expr,
                  extended_block(left_root, right_root, loop_stack)
                ])

                block = right_root
              end
            end
          elsif block.targets.count == 1
            block = block.targets.first
          elsif block == @cfg.exit
            break
          else
            raise "invalid target count (#{block.targets.count})"
          end
        end

        AST::Node.new(:begin, nodes)
      end

      # Block B is completely dominated by another block D if
      # it is dominated by D and no edges ever lead to block B
      # from any other block, including those dominated by D,
      # but excluding any back edges.
      def completely_dominated?(block, dominator)
        if @loops.include?(block)
          (block.sources - @loops[block].to_a) == [dominator]
        else
          block.sources == [dominator]
        end
      end

      # A merge point for blocks R (root), L (left) and D (right)
      # is first block found with BFS starting at {L,D} so that
      # it is dominated by R, but not L or D.
      def find_merge_point(root, left, right, loop_stack)
        worklist = Set[left, right]
        visited  = Set[root, left, right]

        while worklist.any?
          node = worklist.first
          worklist.delete node

          visited.add node

          if (@dom[node].include?(root) &&
              !(@dom[node].include?(left) ||
                @dom[node].include?(right))) ||
              loop_stack.include?(node)
            return node
          end

          node.targets.each do |target|
            next if visited.include? target
            worklist.add target
          end
        end

        # The paths have diverged.
        nil
      end

      # Check if the control transfer is nonlocal according to the
      # innermost loop and adjust @loop_nonlocal accordingly for labels
      # to be inserted where appropriate.
      def check_nonlocal_loop(loop_stack, block)
        if loop_stack.first != block
          @loop_nonlocal.add block

          yield [loop_label(block)]
        else
          yield []
        end
      end

      def loop_label(block)
        "label#{block.label}"
      end

      def normalize_cti_expr(block, negate)
        if negate
          AST::Node.new(:!, [ block.cti.children[1] ])
        else
          block.cti.children[1]
        end
      end
    end
  end
end