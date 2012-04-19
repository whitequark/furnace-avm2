module Furnace::AVM2::ABC
  class AS3Decrement < Opcode
    instruction 0x93

    consume 1
    produce 1

    type :number
  end
end