module Furnace::AVM2::ABC
  class AS3GetSlot < Opcode
    instruction 0x6c
    read_barrier :memory

    body do
      vuint30 :slotindex
    end

    consume 1
    produce 1

    def parameters
      [ body.slotindex ]
    end
  end
end