module AVM2::ABC
  class TraitSlot < IndirectlyNestedRecord
    vuint30 :slot_id
    vuint30 :type_name
    vuint30 :vindex
    uint8   :vkind, :onlyif => lambda { vindex != 0 }
  end
end
