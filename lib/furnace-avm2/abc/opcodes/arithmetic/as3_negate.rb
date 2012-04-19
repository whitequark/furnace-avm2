module Furnace::AVM2::ABC
  class AS3Negate < Opcode
    instruction 0x90

    consume 1
    produce 1

    type :number
  end
end