module Furnace::AVM2::ABC
  class TraitSlot < Record
    include RecordWithValue

    vuint30    :idx
    const_ref  :type,   :multiname

    vuint30    :value_idx

    uint8      :value_kind_raw, :if => lambda { value_idx != 0 }
    xlat_field :value_kind

    def to_astlet(trait)
      AST::Node.new(:slot, [ (trait.name ? trait.name.to_astlet : nil), (type ? type.to_astlet : nil), value, idx ])
    end

    def collect_ns(options)
      if type
        type.collect_ns(options)
      else
        []
      end
    end
  end
end
