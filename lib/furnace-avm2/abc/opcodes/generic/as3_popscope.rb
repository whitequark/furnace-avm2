module Furnace::AVM2::ABC
  class AS3PopScope < Opcode
    instruction 0x1d
    write_barrier :scope

    consume 0
    produce 0
  end
end