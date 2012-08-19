module Furnace::AVM2::ABC
  class AS3AlchemyStoreInt16 < Opcode
    instruction 0x3b
    write_barrier :memory

    consume 2
    produce 0
  end
end