module Furnace::AVM2::ABC
  class AS3GetGlobalScope < Opcode
    instruction 0x64
    read_barrier :scope

    consume 0
    produce 1
  end
end