module Furnace::AVM2::ABC
  class AS3HasNext < Opcode
    instruction 0x1f
    write_barrier :memory

    consume 2
    produce 1
  end
end