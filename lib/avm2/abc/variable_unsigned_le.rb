module AVM2::ABC
  class VariableUnsignedLE < BinData::BasePrimitive
    def value_to_binary_string(value)
      value = value.abs
      bytes = []
      has_more = 0

      loop do
        seven_bit_byte = value & 0x7f
        value >>= 7

        has_more = 0x80
        byte = seven_bit_byte

        bytes.unshift(byte)

        break if value.zero?
      end

      bytes.pack("C*")
    end

    def read_and_return_value(io)
      value = 0
      bit_shift = 0

      loop do
        byte = read_uint8(io)
        has_more = byte & 0x80
        seven_bit_byte = byte & 0x7f

        value <<= bit_shift
        value  |= seven_bit_byte

        bit_shift += 7

        break if has_more.zero?
      end

      value
    end

    def sensible_default
      0
    end

    def read_uint8(io)
      io.readbytes(1).unpack("C").at(0)
    end
  end
end