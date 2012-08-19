module Furnace::AVM2::ABC
  class AS3AlchemyLoadInt8 < Opcode
    instruction 0x35
    read_barrier :memory

    consume 1
    produce 1
  end
end