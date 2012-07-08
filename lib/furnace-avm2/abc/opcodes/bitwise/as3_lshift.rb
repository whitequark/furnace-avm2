module Furnace::AVM2::ABC
  class AS3Lshift < Opcode
    instruction 0xa5
    write_barrier :memory

    consume 2
    produce 1
  end
end