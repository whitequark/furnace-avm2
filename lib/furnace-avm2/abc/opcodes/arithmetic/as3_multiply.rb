module Furnace::AVM2::ABC
  class AS3Multiply < ArithmeticOpcode
    instruction 0xa2

    consume 2
    produce 1

    type :number
  end
end