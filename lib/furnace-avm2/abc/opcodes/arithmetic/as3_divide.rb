module Furnace::AVM2::ABC
  class AS3Divide < Opcode
    instruction 0xa3

    consume 2
    produce 1

    type :number
  end
end