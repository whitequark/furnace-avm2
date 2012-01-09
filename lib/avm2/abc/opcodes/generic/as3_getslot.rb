module AVM2::ABC
  class AS3GetSlot < Opcode
    instruction 0x6c
    vuint30 :slotindex

    consume 1
    produce 1
  end
end