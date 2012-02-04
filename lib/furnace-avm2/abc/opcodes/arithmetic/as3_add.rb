module Furnace::AVM2::ABC
  class AS3Add < ArithmeticOpcode
    instruction 0xa0

    consume 2
    produce 1
  end
end