module AVM2::ABC
  class TraitSlot < Record
    vuint30 :slot_id
    vuint30 :type_name
    vuint30 :vindex
    uint8   :vkind, :if => lambda { vindex != 0 }

    def to_astlet(trait)
    end
  end
end
