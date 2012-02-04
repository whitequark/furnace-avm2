module Furnace::AVM2::ABC
  class AS3NextValue < Opcode
    instruction 0x23

    consume 2
    produce 1
  end
end