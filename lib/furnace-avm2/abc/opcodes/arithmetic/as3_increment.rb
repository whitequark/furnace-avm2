module Furnace::AVM2::ABC
  class AS3Increment < ArithmeticOpcode
    instruction 0x91

    consume 1
    produce 1

    type :number
  end
end