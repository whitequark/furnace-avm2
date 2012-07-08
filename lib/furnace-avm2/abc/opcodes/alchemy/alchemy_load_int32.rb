module Furnace::AVM2::ABC
  class AS3AlchemyLoadInt32 < Opcode
    instruction 0x37
    read_barrier :memory

    consume 1
    produce 1
  end
end