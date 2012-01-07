module AS3
  module Opcodes
    class Branch < Opcode
      class Record < BinData::Record
        endian :little

        uint8 :type
        int24 :target
      end

      attr_reader :target

      def initialize(stream, bytes)
        super(stream)

        @record = Record.read(bytes)
      end

      def prepare!
        @target = @stream.opcode_at_offset(offset + length + @record.target)
      end

      def update!
        @record.target = target.offset - offset - length
      end

      def description
        "_as3_X_BRANCH to:~#{@target.serial}"
      end

      def conditional?
        @record.type != 0x10
      end
    end
  end
end