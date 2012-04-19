module Furnace::AVM2::ABC
  class AS3Modulo < Opcode
    instruction 0xa4

    consume 2
    produce 1

    type :number
  end
end
