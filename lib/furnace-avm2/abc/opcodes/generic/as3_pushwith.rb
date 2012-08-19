module Furnace::AVM2::ABC
  class AS3PushWith < Opcode
    instruction 0x1c
    write_barrier :scope

    consume 1
    produce 0
  end
end