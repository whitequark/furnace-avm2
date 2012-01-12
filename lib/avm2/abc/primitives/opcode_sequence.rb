module AVM2::ABC
  class OpcodeSequence < ::Array
    attr_reader :root, :parent

    def initialize(options={})
      @root, @parent = options[:root], options[:parent]
    end

    def read(io)
      last_instruction = io.pos + @parent.code_length

      while io.pos < last_instruction
        instruction = io.read(1).unpack("C").at(0)

        opcode = Opcode::MAP[instruction]
        if opcode.nil?
          raise "Unknown opcode 0x#{instruction.to_s(16)}"
        end

        element = opcode.new(self)
        element.read(io)

        self << element
      end
    end

    def write(io)
      each do |opcode|
        opcode.write(io)
      end
    end

    def byte_length
      map(&:byte_length).reduce(0, :+)
    end
  end
end