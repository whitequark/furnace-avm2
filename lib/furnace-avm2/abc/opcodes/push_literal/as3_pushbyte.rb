module Furnace::AVM2::ABC
  class AS3PushByte < PushLiteralOpcode
    instruction 0x24

    body do
      uint8 :value
    end

    type :integer
  end
end