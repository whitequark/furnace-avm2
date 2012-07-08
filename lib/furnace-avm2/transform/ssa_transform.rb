module Furnace::AVM2
  module Transform
    class SSATransform
      def transform(cfg)
        @cfg     = cfg
        @stacks  = { cfg.entry => [] }

        info     = {}

        next_rid = 0
        worklist = Set[cfg.entry]
        visited  = Set[]
        while worklist.any?
          node = worklist.first
          worklist.delete node
          visited.add node

          stack   = @stacks[node].dup
          opnodes = []

          node_info = {
            sets: Set[],
            gets: Set[],
          }

          node.insns.each do |opcode|
            case opcode
            when ABC::AS3Dup
              top = consume(stack, 1, node_info)
              produce(stack, top,     node_info)
              produce(stack, top.dup, node_info)

            when ABC::AS3Swap
              a, b = consume(stack, 2, node_info)
              produce(stack, a, node_info)
              produce(stack, b, node_info)

            when ABC::AS3Pop
              consume(stack, 1, nil)

            else
              opnode = AST::Node.new(opcode.ast_type, [], label: opcode.offset)

              parameters = consume(stack, opcode.consumes, node_info)
              if opcode.consumes_context
                context = opcode.context(consume(stack, opcode.consumes_context, node_info))
              end

              opnode.children.concat context if context
              opnode.children.concat opcode.parameters
              opnode.children.concat parameters

              if opcode.produces == 1
                opnode = s(next_rid, opnode)
                produce(stack, next_rid, node_info)

                next_rid += 1
              end

              opnodes.push(opnode)

              if node.cti == opcode
                node.cti = opnode
              end
            end
          end

          node.insns = opnodes

          node.targets.each do |target|
            @stacks[target] = stack
            worklist.add target unless visited.include? target
          end

          info[node] = node_info
          node.insns.push \
              AST::Node.new(:info, [
                AST::Node.new(:sets, node_info[:sets].to_a),
                AST::Node.new(:gets, node_info[:gets].to_a),
              ])
        end

        [ @cfg, info ]
      end

      private

      def r(id)
        AST::Node.new(:r, [ id.to_i ])
      end

      def s(id, wat)
        AST::Node.new(:s, [ id.to_i, wat.to_astlet ])
      end

      def consume(stack, count, info)
        if count == 0
          []
        elsif count <= stack.size
          stack.slice!(-count..-1).map do |id|
            info[:gets].add(id) if info
            r(id)
          end
        else
          raise "cannot consume #{count}: stack underflow with #{stack.size}"
        end
      end

      def produce(stack, id, info)
        info[:sets].add(id) if info
        stack.push id
      end
    end
  end
end