module Furnace::AVM2::ABC
  class AS3BitAnd < Opcode
    instruction 0xa8
    write_barrier :memory

    consume 2
    produce 1
  end
end