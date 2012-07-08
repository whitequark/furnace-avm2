module Furnace::AVM2
  module Transform
    class SSATransform
      def transform(cfg)
        @cfg     = cfg
        @stacks  = { cfg.entry => [] }

        next_rid = 0
        worklist = Set[cfg.entry]
        visited  = Set[]
        while worklist.any?
          node = worklist.first
          worklist.delete node
          visited.add node

          stack   = @stacks[node].dup
          opnodes = []

          node.insns.each do |opcode|
            opnode = AST::Node.new(opcode.ast_type, [], label: opcode.offset)

            parameters = consume(stack, opcode.consumes)
            if opcode.consumes_context
              context = opcode.context(consume(stack, opcode.consumes_context))
            end

            opnode.children.concat context if context
            opnode.children.concat opcode.parameters
            opnode.children.concat parameters

            if opcode.produces == 1
              opnode = s(next_rid, opnode)
              produce(stack, r(next_rid))

              next_rid += 1
            end

            opnodes.push(opnode)

            if node.cti == opcode
              node.cti = opnode
            end
          end

          node.insns = opnodes

          node.targets.each do |target|
            @stacks[target] = stack
            worklist.add target unless visited.include? target
          end
        end

        [ @cfg ]
      end

      private

      def r(id)
        AST::Node.new(:r, [ id.to_i ])
      end

      def s(id, wat)
        AST::Node.new(:s, [ id.to_i, wat.to_astlet ])
      end

      def consume(stack, count)
        if count == 0
          []
        elsif count <= stack.size
          stack.slice!(-count..-1)
        else
          raise "cannot consume #{count}: stack underflow with #{stack.size}"
        end
      end

      def produce(stack, what)
        stack.push what
      end
    end
  end
end