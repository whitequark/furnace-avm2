module Furnace::AVM2::ABC
  class AS3BitXor < Opcode
    instruction 0xaa

    consume 2
    produce 1
  end
end