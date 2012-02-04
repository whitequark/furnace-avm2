module Furnace::AVM2::ABC
  class AS3GetLex < Opcode
    instruction 0x60

    body do
      const_ref :property, :multiname
    end

    consume 0
    produce 1

    def parameters
      [ body.property.to_astlet ]
    end
  end
end