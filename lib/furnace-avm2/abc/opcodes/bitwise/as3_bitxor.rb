module Furnace::AVM2::ABC
  class AS3BitXor < Opcode
    instruction 0xaa
    write_barrier :memory

    consume 2
    produce 1
  end
end