module Furnace::AVM2::ABC
  class AS3Rshift < Opcode
    instruction 0xa6
    write_barrier :memory

    consume 2
    produce 1
  end
end