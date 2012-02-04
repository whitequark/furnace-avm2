module Furnace::AVM2::ABC
  class AS3Modulo < ArithmeticOpcode
    instruction 0xa4

    consume 2
    produce 1

    type :number
  end
end
