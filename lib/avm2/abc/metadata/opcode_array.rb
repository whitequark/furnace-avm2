module AVM2::ABC
  class OpcodeArray < BinData::Array
    mandatory_parameter :initial_byte_length

    def do_read(io)
      bytes_total = eval_parameter(:initial_byte_length)

      string = io.readbytes(bytes_total)
      sub_io = StringIO.new(string)
      bin_io = BinData::IO.new(sub_io)

      until sub_io.eof?
        instruction = string[sub_io.pos].ord

        opcode = Opcode::MAP[instruction]
        if opcode.nil?
          raise "Unknown opcode 0x#{instruction.to_s(16)}"
        end

        element = opcode.new(nil, self)
        element.do_read(bin_io)

        elements << element
      end
    end

    def do_write(io)
      sub_io = StringIO.new
      bin_io = BinData::IO.new(sub_io)

      each do |opcode|
        opcode.do_write(bin_io)
      end

      io.writebytes(sub_io.string)
    end
  end
end