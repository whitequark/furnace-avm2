module Furnace::AVM2::ABC
  class AS3PushScope < Opcode
    instruction 0x30
    write_barrier :scope

    consume 1
    produce 0
  end
end