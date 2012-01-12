module AVM2::ABC
  class AS3SetSlot < Opcode
    instruction 0x6d

    body do
      vuint30 :slotindex
    end

    consume 2
    produce 0
  end
end