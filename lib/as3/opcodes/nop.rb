module AS3
  module Opcodes
    class NOP < Opcode
      class Record < BinData::Record
        endian :little

        uint8 :type
      end

      def initialize(stream, bytes=nil)
        super(stream)

        if bytes
          @record = Record.read(bytes)
        else
          @record = Record.new
          @record.type = 0x2
        end
      end

      def description
        "_as3_nop"
      end
    end
  end
end