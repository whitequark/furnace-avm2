module Furnace::AVM2::ABC
  class AS3AlchemyLoadFloat64 < Opcode
    instruction 0x39
    read_barrier :memory

    consume 1
    produce 1
  end
end