module AVM2::ABC
  class OptionDetail < Record
    vuint30    :value_idx
    uint8      :value_kind_raw
  end
end
