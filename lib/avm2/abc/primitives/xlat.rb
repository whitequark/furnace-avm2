module AVM2::ABC
  module XlatMixin
    def get
      xlat_direct[@value]
    end

    def set(new_value)
      unless xlat_inverse.has_key? new_value
        raise ArgumentError, "Unknown xlat identifier #{new_value} for #{parent.class}"
      end

      assign xlat_inverse[new_value]
    end

    protected

    def hook_after_do_read
      unless xlat_direct.has_key? value
        raise BinData::ValidityError, "Unknown xlat value #{value} for #{parent.class}"
      end
    end

    def xlat_direct
      parent.class.xlat_direct
    end

    def xlat_inverse
      parent.class.xlat_inverse
    end
  end

  # BinData::Registry is too hard to patch.
  class XlatUint8 < BinData::Uint8
    include XlatMixin
  end

  class XlatBit4 < BinData::Bit4
    include XlatMixin
  end
end