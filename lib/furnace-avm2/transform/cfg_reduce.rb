module Furnace::AVM2
  module Transform
    class CFGReduce
      def initialize(options={})
        @verbose = options[:verbose] || false

        #@verbose = true
      end

      def transform(cfg)
        @cfg   = cfg

        @dom   = @cfg.dominators
        @loops = @cfg.identify_loops

        @visited       = Set.new
        @loop_tails    = {}
        @loop_nonlocal = Set.new

        ast, = extended_block(@cfg.entry)

        @visited.add @cfg.exit
        if @visited != @cfg.nodes
          raise "failsafe: not all blocks visited (#{(@cfg.nodes - @visited).map(&:label).join(", ")} left)"
        end

        ast
      end

      def possibly_wrap_eh(block, nodes, exception, loop_stack, nesting)
        if nodes.any?
          if exception.nil?
            nodes
          else
            log nesting, "exception dispatcher"

            unless exception.cti.type == :exception_dispatch
              raise "invalid exception cti"
            end

            @visited.add exception

            catches  = exception.cti.children
            handlers = []

            root, *tails = find_merge_point([ block ] + exception.targets)
            exception.targets.zip(tails).each_with_index do |(target, tail), index|
              exception, var = catches[index].children

              log nesting, "catch #{exception.inspect} #{var.inspect}"

              handler = extended_block(target, tail, loop_stack, nesting + 1, nil)
              handlers.push AST::Node.new(:catch, [
                exception, var,
                handler
              ], catches[index].metadata)
            end

            [ AST::Node.new(:try, [
                AST::Node.new(:begin, nodes),
              ] + handlers) ]
          end
        else
          []
        end
      end

      def extended_block(block, stopgap=nil, loop_stack=[], nesting=0, upper_exc=nil)
        nodes = []
        prev_block = nil
        current_exception = upper_exc
        current_nodes     = []
        exception_changed = false

        while block
          log nesting, "EX: #{(current_exception.label if current_exception) || '-'} " <<
                       "NEW-EX: #{(block.exception.label if block.exception) || '-'}"
          if block.exception != current_exception
            nodes.concat possibly_wrap_eh(prev_block, current_nodes, current_exception, loop_stack, nesting)

            current_exception = block.exception
            current_nodes     = []
            exception_changed = true
          end

          log nesting, "BLOCK: #{block.inspect}"

          prev_block = block

          if @loops.include?(block) && loop_stack.include?(block)
            # We have just arrived to loop head. Insert `continue'
            # and exit.
            check_nonlocal_loop(loop_stack, block) do |params|
              current_nodes << AST::Node.new(:continue, params)
            end
            break
          elsif @loop_tails.include?(block) &&
                    loop_stack.include?(@loop_tails[block])
            # We have just arrived to loop tail. Insert `break'
            # and exit.
            loop = @loop_tails[block]
            check_nonlocal_loop(loop_stack, loop) do |params|
              current_nodes << AST::Node.new(:break, params)
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
            current_nodes << insn
          end

          if block.cti
            if block.cti.type == :lookup_switch
              # this is a switch

              raise "lookup-switch is not implemented"
            elsif @loops.include?(block)
              log nesting, "is a loop"

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

              body = extended_block(in_root, nil, [ block ] + loop_stack, nesting + 1, current_exception)

              # [(label name)]
              # We first parse the body and then add the label before
              # the loop body if anything in the body requires that label
              # to be present.
              if @loop_nonlocal.include?(block)
                current_nodes << AST::Node.new(:label, [ loop_label(block) ])
              end

              # (while (condition)
              #   (body ...))
              current_nodes << AST::Node.new(:while, [
                expr,
                body
              ])

              block = out_root
            else
              log nesting, "is a conditional"

              # this is an `if'.
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
                # Yes. Find merge point.

                # The function technically finds two merge points,
                # but in case of two heads they're identical.
                merge, * = find_merge_point([ left_root, right_root ])

                # If the merge search did not yield a valid node, use
                # stopgap for the current block to avoid runaway code
                # synthesis.
                #
                # The stopgap block is actually an innermost block from
                # a stopgap block set implicitly represented by a set of
                # objects contained in arguments of recursive calls. As
                # the `if's are fully nested when well-formed, we can only
                # check for collision with innermost stopgap block.

                log nesting, "left"
                left_code  = extended_block(left_root,  merge || stopgap, loop_stack, nesting + 1, current_exception)

                log nesting, "right"
                right_code = extended_block(right_root, merge || stopgap, loop_stack, nesting + 1, current_exception)

                current_nodes << AST::Node.new(:if, [ expr, left_code, right_code ])

                block = merge
              else
                # No. The "right root" is actually post-if code.

                log nesting, "one-way"
                code = extended_block(left_root, right_root, loop_stack, nesting + 1, current_exception)

                current_nodes << AST::Node.new(:if, [ expr, code ])

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

        if exception_changed || nesting == 0
          nodes.concat possibly_wrap_eh(prev_block, current_nodes, current_exception, loop_stack, nesting)
        else
          nodes = current_nodes
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

      # Find a set of merge points for a set of partially diverged
      # paths beginning from `heads'.
      # E.g. here:
      #
      #      ----<---
      #     /        \
      #    A -------- B --
      #    |\             \
      #    | C ---- E - F--- <exit>
      #    |      /
      #     \- D -
      #
      # with A as the root and B, C and E as heads, the function reports
      # following merge points: E for C and D, and nil for B.
      # Note that back edge (denoted by < in the picture) is ignored.
      def find_merge_point(heads)
        seen  = Set[]

        heads.map do |head|
          # Trail is an ordered collection of nodes encountered during
          # BFS. Order of nodes with same rank is irrelevant.
          trail = []

          worklist = Set[head]
          visited  = Set[head]
          while worklist.any?
            node = worklist.first
            worklist.delete node

            visited.add node
            trail.push node

            # Nodes which are dominated by the current head aren't relevant
            # for merge point search and will cause false positives.
            unless @dom[node].include? head
              seen.add node
            end

            node.targets.each do |target|
              # Skip visited nodes.
              if visited.include?(target)
                next
              end

              # Skip back edges.
              if @loops[target] && @loops[target].include?(node)
                next
              end

              worklist.add target
            end
          end

          trail
        end.map do |(head, *trail)|
          trail.find do |trail_elem|
            seen.include?(trail_elem)
          end
        end.map do |tail|
          tail unless tail == @cfg.exit
        end
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

      private

      def log(nesting, what)
        $stderr.puts "CFGr: #{"  " * nesting}#{what}" if @verbose
      end
    end
  end
end