module AVM2::ABC
  class AS3PushString < PushLiteralOpcode
    instruction 0x2c

    body do
      const_ref :value, :string
    end

    type :string
  end
end