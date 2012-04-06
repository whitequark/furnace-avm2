module Furnace::AVM2::ABC
  class AS3Urshift < BitwiseOpcode
    instruction 0xa7

    consume 2
    produce 1
  end
end