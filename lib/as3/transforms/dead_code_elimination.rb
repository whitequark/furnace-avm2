module AS3
  module Transforms
    class DeadCodeElimination
      def run(stream)
        cfg = stream.build_cfg
        dead_opcodes = []

        cfg.nodes.each do |node|
          if node.label != 0 && node.entering_edges.count == 0
            dead_opcodes += node.operations
          end
        end

        dead_opcodes.each do |opcode|
          stream.opcodes.delete opcode
        end

        stream.opcodes.each &:update!

        stream.opcodes.delete_if do |opcode|
          opcode.redundant?
        end
      end
    end
  end
end