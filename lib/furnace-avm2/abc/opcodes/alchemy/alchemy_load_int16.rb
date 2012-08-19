module Furnace::AVM2::ABC
  class AS3AlchemyLoadInt16 < Opcode
    instruction 0x36
    read_barrier :memory

    consume 1
    produce 1
  end
end