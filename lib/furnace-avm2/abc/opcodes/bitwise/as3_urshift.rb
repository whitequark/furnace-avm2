module Furnace::AVM2::ABC
  class AS3URShift < BitwiseOpcode
    instruction 0xa7

    consume 2
    produce 1
  end
end