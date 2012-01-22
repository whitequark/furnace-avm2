module AVM2::ABC
  class AS3PushInt < PushLiteralOpcode
    instruction 0x2d

    body do
      const_ref :value, :int
    end

    type :integer
  end
end