module Furnace::AVM2::ABC
  class AS3BitNot < Opcode
    instruction 0x97
    write_barrier :memory

    consume 1
    produce 1
  end
end