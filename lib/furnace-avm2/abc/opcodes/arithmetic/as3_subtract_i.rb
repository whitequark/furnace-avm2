module Furnace::AVM2::ABC
  class AS3SubtractI < ArithmeticOpcode
    instruction 0xc6

    consume 2
    produce 1

    type :integer
  end
end