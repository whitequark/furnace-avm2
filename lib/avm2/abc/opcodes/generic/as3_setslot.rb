module AVM2::ABC
  class AS3SetSlot < Opcode
    instruction 0x6d
    vuint30 :slotindex

    consume 2
    produce 0
  end
end