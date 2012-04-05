module Furnace::AVM2::ABC
  class DefaultValue < Record
    include RecordWithValue

    vuint30    :value_idx

    uint8      :value_kind_raw
    xlat_field :value_kind
  end
end
