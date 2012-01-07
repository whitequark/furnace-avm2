module AS3
  module Opcodes
    class Unknown < Opcode
      attr_reader :bytes, :description

      def initialize(stream, bytes, description)
        super stream

        @bytes = bytes
        @description = description
      end

      def length
        @bytes.length
      end
    end
  end
end