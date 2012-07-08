module Furnace::AVM2::ABC
  class AS3AlchemyStoreFloat32 < Opcode
    instruction 0x3d
    write_barrier :memory

    consume 2
    produce 0
  end
end