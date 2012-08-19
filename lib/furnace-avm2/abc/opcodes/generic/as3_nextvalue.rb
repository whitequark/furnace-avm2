module Furnace::AVM2::ABC
  class AS3NextValue < Opcode
    instruction 0x23
    write_barrier :memory

    consume 2
    produce 1
  end
end