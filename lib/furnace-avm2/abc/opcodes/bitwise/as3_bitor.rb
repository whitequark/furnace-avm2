module Furnace::AVM2::ABC
  class AS3BitOr < BitwiseOpcode
    instruction 0xa9

    consume 2
    produce 1
  end
end