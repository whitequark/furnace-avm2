module Furnace::AVM2::ABC
  class AS3NextName < Opcode
    instruction 0x1e
    write_barrier :memory

    consume 2
    produce 1
  end
end