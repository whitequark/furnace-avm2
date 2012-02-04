module Furnace::AVM2::ABC
  class AS3PushShort < PushLiteralOpcode
    instruction 0x25

    body do
      vuint30 :value
    end

    type :integer
  end
end