module AVM2::ABC
  class OpcodeArray < BinData::Array
    mandatory_parameter :initial_byte_length

    def do_read(io)
      bytes_total = eval_parameter(:initial_byte_length)
      sub_io = StringIO.new(io.readbytes(bytes_total))
      bin_io = BinData::IO.new(sub_io)

      until sub_io.eof?
        instruction = sub_io.getbyte
        sub_io.ungetbyte(instruction)

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