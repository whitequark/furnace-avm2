module Furnace::AVM2::ABC
  class AS3AlchemyLoadFloat32 < Opcode
    instruction 0x38
    read_barrier :memory

    consume 1
    produce 1
  end
end