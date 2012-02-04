module Furnace::AVM2::ABC
  class AS3Coerce < TypeConversionOpcode
    instruction 0x80

    body do
      const_ref :type, :multiname
    end

    consume 1
    produce 1

    def parameters
      [ body.type.to_astlet ]
    end
  end
end