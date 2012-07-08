module Furnace::AVM2::ABC
  class AS3AlchemyStoreInt32 < Opcode
    instruction 0x3c
    write_barrier :memory

    consume 2
    produce 0
  end
end