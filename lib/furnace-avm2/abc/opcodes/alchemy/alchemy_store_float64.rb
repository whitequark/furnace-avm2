module Furnace::AVM2::ABC
  class AS3AlchemyStoreFloat64 < Opcode
    instruction 0x3e
    write_barrier :memory

    consume 2
    produce 0
  end
end