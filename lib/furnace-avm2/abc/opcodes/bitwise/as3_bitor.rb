module Furnace::AVM2::ABC
  class AS3BitOr < Opcode
    instruction 0xa9
    write_barrier :memory

    consume 2
    produce 1
  end
end