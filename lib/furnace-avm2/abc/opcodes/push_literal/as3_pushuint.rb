module Furnace::AVM2::ABC
  class AS3PushUint < PushLiteralOpcode
    instruction 0x2e

    body do
      const_ref :value, :uint
    end

    type :integer
  end
end