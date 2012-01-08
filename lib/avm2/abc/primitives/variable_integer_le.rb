module AVM2::ABC
  class VariableIntegerLE < BinData::BasePrimitive
    def value_to_binary_string(value)
      if value < 0 && self.class.signed?
        value = -value
        is_negative = true
      else
        is_negative = false
      end

      bytes = []

      begin
        byte = value & 0x7F
        value >>= 7

        if value != 0
          byte |= 0x80
        elsif is_negative
          byte |= 0x40
        end

        bytes.push(byte)
      end while value != 0x00

      bytes.pack("C*")
    end

    def read_and_return_value(io)
      value = 0
      bit_shift = 0

      begin
        byte = io.readbytes(1).unpack("C").at(0)

        value |= (byte & 0x7F) << bit_shift
        bit_shift += 7
      end while byte & 0x80 != 0

      sign_bit = (1 << (bit_shift - 1))
      if self.class.signed? && (value & sign_bit) != 0
        value = -(value & ~sign_bit)
      end

      value
    end

    def sensible_default
      0
    end
  end
end