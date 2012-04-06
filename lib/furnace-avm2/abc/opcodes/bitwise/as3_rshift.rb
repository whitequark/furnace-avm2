module Furnace::AVM2::ABC
  class AS3Rshift < BitwiseOpcode
    instruction 0xa6

    consume 2
    produce 1
  end
end