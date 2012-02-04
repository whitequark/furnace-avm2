module Furnace::AVM2::ABC
  class AS3PushNan < PushLiteralOpcode
    instruction 0x28

    type :nan
  end
end