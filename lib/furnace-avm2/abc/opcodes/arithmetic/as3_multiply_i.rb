module Furnace::AVM2::ABC
  class AS3MultiplyI < ArithmeticOpcode
    instruction 0xc7

    consume 2
    produce 1

    type :integer
  end
end