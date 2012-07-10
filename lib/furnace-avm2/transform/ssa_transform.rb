module Furnace::AVM2
  module Transform
    class SSAMetadata
      attr_reader :sets, :gets
      attr_reader :set_map, :gets_map, :gets_upper

      def initialize(hash={})
        @hash = hash.freeze
        @sets, @gets = Set[], Set[]
        @set_map     = {}
        @gets_map    = Hash.new { |h, k| h[k] = Set[] }
        @gets_upper  = {}
      end

      def [](key)
        @hash[key]
      end

      def any?
        @sets.any? || @gets.any?
      end

      def inspect
        "| sets: #{sets.to_a.join(", ")}" <<
          " gets: #{gets.to_a.join(", ")}"
      end

      def merge!(other)
        @sets.merge other.sets
        @gets.merge other.gets

        @set_map.merge! other.set_map
        @gets_map.merge! other.gets_map { |h, ak, dk| ak + dk }
        @gets_upper.merge! other.gets_upper
      end

      def add_get(id, upper, node)
        @gets.add(id)
        @gets_map[id].add node
        @gets_upper[node] = upper
      end

      def add_set(id, node)
        @sets.add(id)
        @set_map[id] = node
      end
    end

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

          metadata = SSAMetadata.new
          block.metadata = metadata

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
                stack_id = (next_rid += 1)
                toplevel_node = s(stack_id, node)
              else
                toplevel_node = node
              end

              parameters = consume(stack, opcode.consumes, toplevel_node, metadata)
              if opcode.consumes_context
                context = opcode.context(consume(stack, opcode.consumes_context, toplevel_node, metadata))
              end

              node.children.concat context if context
              node.children.concat opcode.parameters
              node.children.concat parameters

              normalizer.visit node

              nodes.push(toplevel_node)

              if opcode.produces == 1
                produce(stack, stack_id, toplevel_node, metadata)
              end

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
        end

        @cfg
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

      def consume(stack, count, node, metadata)
        check_stack! stack, count

        if count == 0
          []
        else
          stack.slice!(-count..-1).map do |id|
            get_node = r(id)

            metadata.add_get(id, node, get_node)

            get_node
          end
        end
      end

      def produce(stack, id, node, metadata)
        metadata.add_set id, node

        stack.push id
      end
    end
  end
end