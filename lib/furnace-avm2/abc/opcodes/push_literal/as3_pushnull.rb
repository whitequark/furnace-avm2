module Furnace::AVM2::ABC
  class AS3PushNull < PushLiteralOpcode
    instruction 0x20

    type :null
  end
end