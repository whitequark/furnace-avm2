module Furnace::AVM2::ABC
  class AS3In < Opcode
    instruction 0xb4
    write_barrier :memory

    consume 2
    produce 1
  end
end