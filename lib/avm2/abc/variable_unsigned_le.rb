module AVM2::ABC
  class VariableUnsignedLE < BinData::BasePrimitive
    def value_to_binary_string(value, signed = false)
      if value < 0 && signed
        value = -value
      else
        signed = false
      end

      bytes = []


      begin
        byte = value & 0x7F
        value >>= 7

        if value != 0
          byte |= 0x80
        elsif signed
          byte |= 0x40
        end

        bytes.push(byte)

      end while value != 0x00

      bytes.pack("C*")
    end

    def read_and_return_value(io, signed = false)
      value = 0
      bit_shift = 0

      begin
        byte = read_uint8(io)

        value |= (byte & 0x7F) << bit_shift
        bit_shift += 7
      end while byte & 0x80 != 0

      if signed && (value & (1 << (bit_shift - 1)) != 0)
        value = -(value & ~(1 << (bit_shift - 1)))
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