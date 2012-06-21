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

        @visited        = Set.new
        @loop_tails     = {}
        @loop_nonlocal  = Set.new

        @postcond_heads = Set.new
        @postcond_tails = Set.new

        @try_tails      = Hash.new { |h,k| h[k] = Set.new }

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
              log nesting, "handler #{catches[index].inspect}"
              handler = extended_block(target, tail || root, loop_stack, nesting + 1, nil)

              node = catches[index]
              if node.type == :catch
                exc_name, var_name = node.children
                handlers.push AST::Node.new(:catch, [
                  exc_name, var_name,
                  handler
                ], node.metadata)
              elsif node.type == :finally
                handlers.push AST::Node.new(:finally, [
                  handler
                ], node.metadata)
              else
                raise "unknown handler type #{node.type}"
              end
            end

            eh_nodes = [ AST::Node.new(:try, [
              AST::Node.new(:begin, nodes),
            ] + handlers) ]

            if tails.any? && tails.uniq.count == 1 &&
                      @dom[tails.first].include?(exception)
              # Handle a special case whether control doesn't flow after tails
              # of the catches by its own, e.g. the last statement of try
              # block is return.

              tail_block = tails.first
            elsif @try_tails.has_key? exception
              # Handle a special case where control falls through more than
              # one level of scopes.
              if @try_tails[exception].count > 1
                raise "multiple try block exit points"
              end

              tail_block = @try_tails[exception].first
            end

            if tail_block
              tail_code = extended_block(tail_block, nil, loop_stack, nesting + 1, nil)
              eh_nodes.concat tail_code.children
            end

            eh_nodes
          end
        else
          []
        end
      end

      def is_loop_head?(block, loop_stack)
        (@loops.include?(block) || @postcond_tails.include?(block)) &&
                    loop_stack.include?(block)
      end

      def is_loop_tail?(block, loop_stack)
        @loop_tails.include?(block) &&
                    loop_stack.include?(@loop_tails[block])
      end

      def extended_block(block, stopgap=nil, loop_stack=[], nesting=0, upper_exc=nil, options={})
        nodes = []
        prev_block = nil
        current_exception = upper_exc
        current_nodes     = []
        exception_changed = false

        log nesting, "--- STOPGAP: #{stopgap.inspect}"

        while block
          log nesting, "BLOCK: #{block.inspect}"

          if is_loop_head?(block, loop_stack)
            if options[:infinite_loop_head]
              # Infinite loop head is a special case where cti_block
              # has back edges pointing to it, but just for once it
              # should not be turned to (continue) statement.
              options.delete(:infinite_loop_head)
            else
              log nesting, "exit: loop head (continue stmt)"

              check_nonlocal_loop(loop_stack, block) do |params|
                current_nodes << AST::Node.new(:continue, params)
              end

              break
            end
          elsif is_loop_tail?(block, loop_stack)
            log nesting, "exit: loop tail (break stmt)"

            loop = @loop_tails[block]
            check_nonlocal_loop(loop_stack, loop) do |params|
              current_nodes << AST::Node.new(:break, params)
            end

            break
          elsif loop_stack.first == block && !@loops.include?(block)
            log nesting, "exit: do..while cti block"
            break
          elsif block == stopgap
            log nesting, "exit: stopgap encountered"
            break
          elsif block.cti && block.cti.type == :exception_dispatch
            log nesting, "exit: spurious exception dispatch traverse"
            break
          elsif !upper_exc.nil? && block.exception.nil? && block != @cfg.exit
            log nesting, "exit: leaving try block"

            @try_tails[upper_exc].add block

            break
          elsif block == @cfg.exit
            # We have just arrived to exit node.
            break
          end

          log nesting, "EX: #{(current_exception.label if current_exception) || '-'} " <<
                       "NEW-EX: #{(block.exception.label if block.exception) || '-'}"

          if block.exception != current_exception
            nodes.concat possibly_wrap_eh(prev_block, current_nodes, current_exception, loop_stack, nesting)

            current_exception = block.exception
            current_nodes     = []
            exception_changed = true
          end

          if @visited.include? block
            raise "failsafe: block #{block.label} already visited"
          end

          prev_block = block
          @visited.add block

          if block.cti
            if block.cti.type == :lookup_switch
              log nesting, "is a switch"

              append_instructions(block, current_nodes)

              # Group cases pointing to the same blocks of code.
              aliases = Hash[block.targets.each_index.
                    group_by { |index| block.targets[index] }.values.
                    map { |(main, *others)| [ main, others ] }]

              # Find a merge point for all of the case branches.
              case_branches = block.targets.values_at(*aliases.keys)
              case_merges   = find_merge_point(case_branches)

              # A possible exit point for the statement is a merge which
              # isn't pointed to by a branch. This prediction can fail if
              # there are empty cases.
              possible_exit_points = (case_merges.compact - case_branches).uniq
              if possible_exit_points.count > 1
                raise "multiple possible switch exit points at first guess"
              end

              exit_point = possible_exit_points.first
              log nesting, "exit point (first guess): #{exit_point.inspect}"

              # Compute case predecessors for fallthrough.
              case_predecessors = Hash.new { |h,k| h[k] = Set.new }

              case_branches.zip(case_merges).each do |(branch, merge)|
                if case_branches.include?(merge)
                  case_predecessors[merge].add branch
                end
              end

              # One and only one block may have multiple predecessors.
              # In this case, it is the actual exit point; switch the
              # prediction.
              new_exit_point, = case_predecessors.find { |branch, pred| pred.count > 1 }
              if new_exit_point
                if case_predecessors.find { |branch, pred|
                        pred.count > 1 && branch != new_exit_point }
                  raise "multiple possible switch exit points at second guess"
                end

                exit_point = new_exit_point
                log nesting, "exit point (second guess): #{exit_point.inspect}"
              end

              if exit_point.nil?
                exit_point = stopgap
                log nesting, "exit point (last restort): stopgap #{stopgap.inspect}"
              end

              # Flatten the one-element sets.
              case_predecessors.each do |branch, pred|
                case_predecessors[branch] = pred.first
              end

              case_successors = case_predecessors.invert

              # Generate code for the actual branches. Stopgap is either the
              # another case (fallthrough) or exit point.
              case_bodies = case_branches.zip(case_merges).map do |(branch, merge)|
                if case_branches.include? merge
                  branch_stopgap = merge
                else
                  branch_stopgap = exit_point
                end

                extended_block(branch, branch_stopgap, loop_stack, nesting + 1, current_exception)
              end

              node = AST::Node.new(:begin)

              # Sort the nodes in the order of fallthrough precedence
              # and assemble the body AST.
              case_pool = case_branches.dup
              while case_pool.any?
                next_branch = case_pool.find { |c| !case_predecessors.has_key?(c) }
                if next_branch.nil?
                  raise "circular dependency between cases"
                end

                body = nil

                while next_branch
                  case_pool.delete next_branch

                  if body && !case_predecessors.has_key?(next_branch)
                    body.children << AST::Node.new(:break)
                  end

                  main_index = block.targets.index(next_branch)
                  body = case_bodies[case_branches.index(next_branch)]

                  [ main_index, *aliases[main_index] ].each do |index|
                    if index == 0
                      node.children << AST::Node.new(:default)
                    else
                      node.children << AST::Node.new(:case, [
                        AST::Node.new(:integer, [ index - 1 ])
                      ])
                    end
                  end

                  node.children << body

                  next_branch = case_successors[next_branch]
                end

                body.children << AST::Node.new(:break)
              end

              current_nodes << AST::Node.new(:switch, [
                block.cti.children.last,
                node
              ])

              block = exit_point
            elsif @loops.include?(block) && !@postcond_heads.include?(block)
              # we're trapped in a strange loop
              if block.insns.first == block.cti &&
                    !(@loops[block].include?(block.targets.first) &&
                      @loops[block].include?(block.targets.last))
                # Make sure that both branch targets don't reside within the
                # loop. If they do, it's a do-while loop.
                log nesting, "is a while loop"

                loop_type = :head_cti
                cti_block = block
              else
                back_edges = []

                @loops[block].each do |loop_block|
                  loop_block.targets.each do |target|
                    # Find a back edge
                    if @dom[loop_block].include? target
                      back_edges << loop_block
                    end
                  end
                end

                if back_edges.count == 1
                  log nesting, "is a do-while loop"

                  loop_type = :tail_cti
                  cti_block = back_edges.first
                else
                  log nesting, "is an infinite loop"

                  loop_type = :infinite
                  cti_block = block
                end
              end

              if loop_type == :infinite
                in_root, out_root = block, nil

                # out_root = nil is not correct in all cases, i.e.
                # when multiple breaks are present.

                expr = AST::Node.new(:true)
              else
                reverse = !cti_block.cti.children[0]
                in_root, out_root = cti_block.targets

                if !@loops[block].include?(in_root)
                  # One of the branch targets should reside within
                  # the loop.
                  in_root, out_root = out_root, in_root
                  reverse = !reverse
                end

                # If we reversed the roots or it was a (jump-if false),
                # then reverse the condition.
                expr = normalize_cti_expr(cti_block, reverse)
              end

              # Mark the loop tail so we could detect `break' and
              # `continue' statements.
              @loop_tails[out_root] = cti_block

              # Remove the block from visited set if it is unrelated to the
              # current loop condition, as it should be re-processed.
              if loop_type != :head_cti
                @visited.delete block

                @postcond_heads.add block
                @postcond_tails.add cti_block
              end

              # Handle a special case: all code in the loop header.
              if loop_type == :tail_cti && cti_block == block
                body = AST::Node.new(:begin)

                append_instructions(block, body.children)
              else
                body = extended_block(in_root, nil, [ cti_block ] + loop_stack, nesting + 1, current_exception,
                        { infinite_loop_head: (loop_type == :infinite) })
              end

              # [(label name)]
              # We first parse the body and then add the label before
              # the loop body if anything in the body requires that label
              # to be present.
              if @loop_nonlocal.include?(block)
                current_nodes << AST::Node.new(:label, [ loop_label(block) ])
              end

              # Map loop types to node types.
              if loop_type == :head_cti || loop_type == :infinite
                loop_node = :while
              else
                loop_node = :do_while
              end

              # (while|do-while (condition)
              #   (body ...))
              current_nodes << AST::Node.new(loop_node, [
                expr,
                body
              ])

              # Add cti_block to visited for the do-while case.
              if loop_type == :tail_cti
                @visited.add cti_block
              end

              block = out_root
            else
              log nesting, "is a conditional"

              append_instructions(block, current_nodes)

              # This is an `if'.
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

              # A special case: empty if().
              if left_root == right_root
                current_nodes << AST::Node.new(:if, [
                  block.cti.children[1],
                  AST::Node.new(:begin)
                ])

                block = left_root

                next
              end

              # If the left root isn't dominated by block,
              # then it can't be `if' branch.
              if !completely_dominated?(left_root, block)
                left_root, right_root = right_root, left_root
                reverse = !reverse
              end

              # If the left root still isn't dominated by block,
              # then this is not a proper conditional.
              # If the left root leads to a loop head or tail, then
              # the code will not be generated for that root, and
              # its dominance is irrelevant.
              if !completely_dominated?(left_root, block) &&
                    !(is_loop_head?(left_root, loop_stack) ||
                      is_loop_tail?(left_root, loop_stack))
                raise "not well-formed if"
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

                merge_left, merge_right = find_merge_point([ left_root, right_root ])

                # One or both of the merge points could be nil, but they will
                # not be different.
                merge = merge_left || merge_right

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
            append_instructions(block, current_nodes)

            block = block.targets.first
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

      def append_instructions(block, nodes)
        block.insns.each do |insn|
          next if insn == block.cti
          nodes << insn
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