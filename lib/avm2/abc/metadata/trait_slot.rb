module AVM2::ABC
  class TraitSlot < Record
    vuint30   :idx
    const_ref :type,   :multiname

    vuint30   :value_idx
    uint8     :value_kind, :if => lambda { value_idx != 0 }

    def to_astlet(trait)
      AST::Node.new(:slot, [ trait.name.to_astlet, type.to_astlet, idx ])
    end
  end
end
