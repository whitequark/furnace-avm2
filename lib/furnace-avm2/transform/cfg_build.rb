module Furnace::AVM2
  module Transform
    class CFGBuild
      def transform(code, body)
        @cfg        = CFG::Graph.new
        @jumps      = Set.new
        @exceptions = {}

        body.exceptions.each_with_index do |exc, index|
          unless exc_block = @exceptions[exc.range]
            exc_block = CFG::Node.new(@cfg, :"exc_#{index}")
            exc_block.metadata[:keep] = true
            exc_block.metadata[:exception] = true

            dispatch_node = AST::Node.new(:exception_dispatch, [])
            exc_block.insns << dispatch_node
            exc_block.cti = dispatch_node

            @exceptions[exc.range] = exc_block
          end

          exc_block.target_labels << exc.target_offset

          if exc.variable
            exc_block.cti.children <<
                AST::Node.new(:catch,
                  [ (exc.exception.to_astlet if exc.exception),
                    exc.variable.to_astlet,
                    exc.target_offset ])
          else
            exc_block.cti.children <<
                AST::Node.new(:finally,
                  [ exc.target_offset ])
          end
        end

        # Handle nested exception handling blocks.

        exceptions_within = Hash.new { |h,k| h[k] = Set[] }

        @exceptions = Hash[
          @exceptions.sort do |(left_range, left), (right_range, right)|
            intersection = (left_range & right_range)
            if intersection.nil?
              0
            elsif intersection == left_range
              exceptions_within[left].add right
              -1
            elsif intersection == right_range
              exceptions_within[right].add left
              1
            else
              raise "impossible exception handler layout"
            end
          end
        ]

        # Set nearest outermost exception handler.

        @exceptions.each do |range, inner|
          if exceptions_within[inner].any?
            inner.exception_label = @exceptions.values.find do |outer|
              exceptions_within[inner].include? outer
            end.label
          end
        end

        @pending_label = nil
        @pending_exc_block = nil
        @pending_exc_range = nil
        @pending_queue = []

        code.each_with_index do |opcode, index|
          unless @pending_label
            @pending_label = opcode.offset

            exception_block_for(@pending_label) do |block, range|
              @pending_exc_block = block
              @pending_exc_range = range
            end
          end

          # Skip nops
          unless [ ABC::AS3Jump, ABC::AS3Label,
                   ABC::AS3Kill, ABC::AS3Nop    ].include? opcode.class
            @pending_queue << opcode
          end

          next_opcode = code[index + 1]
          next_offset = next_opcode.offset if next_opcode

          case opcode
          when ABC::FunctionReturnOpcode
            cutoff(nil, [ nil ])

          when ABC::AS3Throw
            cutoff(opcode, [ ])

          when ABC::AS3Jump
            @jumps.add(opcode.target_offset)
            cutoff(nil, [ opcode.target_offset ])

          when ABC::ControlTransferOpcode
            @jumps.add(opcode.target_offset)
            cutoff(opcode, [ opcode.target_offset, next_offset ])

          when ABC::AS3LookupSwitch
            jump_to = [ opcode.default_target.offset ] +
                            opcode.case_targets.map(&:offset)
            @jumps.merge(jump_to)
            cutoff(opcode, jump_to)

          else
            *, next_exception_block = exception_block_for(next_offset)

            if @jumps.include?(next_offset) || (next_opcode && next_opcode.is_a?(ABC::AS3Label))
              cutoff(nil, [ next_offset ])
            elsif body.exceptions.find { |ex| ex.target_offset == next_offset }
              cutoff(nil, [ next_offset ])
            elsif @pending_exc_block != next_exception_block
              cutoff(nil, [ next_offset ])
            end
          end
        end

        exit_node = CFG::Node.new(@cfg)
        @cfg.nodes.add exit_node
        @cfg.exit = exit_node

        @exceptions.values.each do |exc_node|
          @cfg.nodes.add exc_node
        end

        @cfg.eliminate_unreachable!
        @cfg.merge_redundant!

        @cfg
      end

      private

      def cutoff(cti, targets)
        node = CFG::Node.new(@cfg, @pending_label, @pending_queue, cti, targets)
        if @pending_exc_block
          node.exception_label = @pending_exc_block.label
        end

        if @cfg.nodes.empty?
          @cfg.entry = node
        end

        @cfg.nodes.add node

        @pending_label = nil
        @pending_exc_block = nil
        @pending_exc_range = nil
        @pending_queue = []
      end

      def exception_block_for(offset)
        return nil unless offset

        @exceptions.find do |range, block|
          if range.include? offset
            yield block, range if block_given?
            true
          end
        end
      end
    end
  end
end