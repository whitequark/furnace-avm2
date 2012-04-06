module Furnace::AVM2::ABC
  class AS3Lshift < BitwiseOpcode
    instruction 0xa5

    consume 2
    produce 1
  end
end