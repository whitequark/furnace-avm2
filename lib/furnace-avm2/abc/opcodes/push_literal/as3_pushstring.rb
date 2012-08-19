module Furnace::AVM2::ABC
  class AS3PushString < PushLiteralOpcode
    instruction 0x2c

    body do
      const_ref :value, :string
    end

    def parameters
      [ body.line ]
    end

    type :string
  end
end