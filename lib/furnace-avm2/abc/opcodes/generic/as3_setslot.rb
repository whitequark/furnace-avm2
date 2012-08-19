module Furnace::AVM2::ABC
  class AS3SetSlot < Opcode
    instruction 0x6d
    write_barrier :memory

    body do
      vuint30 :slotindex
    end

    consume 2
    produce 0

    def parameters
      [ body.slotindex ]
    end
  end
end