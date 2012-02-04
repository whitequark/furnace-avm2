module Furnace::AVM2::ABC
  class AS3PushDouble < PushLiteralOpcode
    instruction 0x2f

    body do
      vuint30 :value
    end

    type :double
  end
end