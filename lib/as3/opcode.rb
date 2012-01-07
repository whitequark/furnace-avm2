module AS3
  class Opcode
    attr_reader :stream, :record

    def initialize(stream)
      @stream = stream
    end

    def length
      @record.num_bytes
    end

    def bytes
      @record.to_binary_s.bytes.to_a
    end

    def description
      "undefined"
    end

    def serial
      @stream.serial_for self
    end

    def offset
      @stream.offset_for self
    end

    def prepare!
    end

    def update!
    end

    def replace_with_nops!
      position = self.serial

      @stream.opcodes.delete_at(position)
      @stream.opcodes.insert(position, *self.length.times.map { Opcodes::NOP.new(@stream) } )
    end

    def to_s
      "#{serial} #{description}"
    end
  end
end