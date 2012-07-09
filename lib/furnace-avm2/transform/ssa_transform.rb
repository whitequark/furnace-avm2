module Furnace::AVM2
  module Transform
    class SSATransform
      class ASTNormalizer
        include Furnace::AST::StrictVisitor

        # (if-* a b) -> (branch-if (*' a b))
        BINARY_IF_MAPPING = {
          :eq        => [false, :==],
          :ne        => [false, :!=],
          :ge        => [false, :>=],
          :nge       => [true,  :>=],
          :gt        => [false, :>],
          :ngt       => [true,  :>],
          :le        => [false, :<=],
          :nle       => [true,  :<=],
          :lt        => [false, :<],
          :nlt       => [true,  :<],
          :strict_eq => [false, :===],
          :strict_ne => [true,  :===], # Why? Because of (lookup-switch ...).
        }

        BINARY_IF_MAPPING.each do |cond, (positive, comp)|
          define_method :"on_if_#{cond}" do |node|
            node.update(:branch_if, [
              positive,
              AST::Node.new(comp, node.children)
            ])
          end
        end

        [true, false].each do |cond|
          define_method :"on_if_#{cond}" do |node|
            node.update(:branch_if, [
              cond,
              node.children.first
            ])
          end
        end
      end

      def transform(cfg)
        @cfg     = cfg
        @stacks  = { cfg.entry => [] }
        info     = {}

        normalizer = ASTNormalizer.new

        next_rid = 0
        worklist = Set[cfg.entry]
        visited  = Set[]
        while worklist.any?
          block = worklist.first
          worklist.delete block
          visited.add block

          stack   = @stacks[block].dup
          nodes = []

          block_info = {
            sets:       Set[],
            gets:       Set[],
            set_map:    {},
            gets_map:   Hash.new { |h, k| h[k] = Set[] },
            gets_upper: {},
          }

          block.insns.each do |opcode|
            case opcode
            when ABC::AS3Dup
              check_stack! stack, 1
              stack.push stack.last

            when ABC::AS3Swap
              check_stack! stack, 2
              a, b = stack.pop, stack.pop
              stack.push a, b

            when ABC::AS3Pop
              check_stack! stack, 1
              stack.pop

            else
              node = AST::Node.new(opcode.ast_type, [], opcode.metadata)

              if opcode.produces == 1
                toplevel_node = s(next_rid, node)
                produce(stack, next_rid, toplevel_node, block_info)

                next_rid += 1
              else
                toplevel_node = node
              end

              parameters = consume(stack, opcode.consumes, toplevel_node, block_info)
              if opcode.consumes_context
                context = opcode.context(consume(stack, opcode.consumes_context, toplevel_node, block_info))
              end

              node.children.concat context if context
              node.children.concat opcode.parameters
              node.children.concat parameters

              normalizer.visit node

              nodes.push(toplevel_node)

              if block.cti == opcode
                block.cti = node
              end
            end
          end

          block.insns = nodes

          block.targets.each do |target|
            @stacks[target] = stack
            worklist.add target unless visited.include? target
          end

          info[block] = block_info

          block.insns.push \
              AST::Node.new(:_info, [
                AST::Node.new(:sets, [ block_info[:sets] ]),
                AST::Node.new(:gets, [ block_info[:gets] ]),
              ])
        end

        [ @cfg, info ]
      end

      private

      def r(id)
        AST::Node.new(:r, [ id.to_i ])
      end

      def s(id, wat)
        metadata = {}
        [ :read_barrier, :write_barrier ].each do |key|
          if value = wat.metadata.delete(key)
            metadata[key] = value
          end
        end

        AST::Node.new(:s, [ id.to_i, wat.to_astlet ],
              metadata)
      end

      def check_stack!(stack, count)
        if count > stack.size
          raise "cannot consume #{count}: stack underflow with #{stack.size}"
        end
      end

      def consume(stack, count, node, info)
        check_stack! stack, count

        if count == 0
          []
        else
          stack.slice!(-count..-1).map do |id|
            get_node = r(id)

            info[:gets].add(id)
            info[:gets_map][id].add get_node
            info[:gets_upper][get_node] = node

            get_node
          end
        end
      end

      def produce(stack, id, node, info)
        info[:sets].add(id)
        info[:set_map][id] = node

        stack.push id
      end
    end
  end
end