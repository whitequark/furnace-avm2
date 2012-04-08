module Furnace::AVM2::ABC
  class AS3PushByte < PushLiteralOpcode
    instruction 0x24

    body do
      int8 :value
    end

    type :integer
  end
end