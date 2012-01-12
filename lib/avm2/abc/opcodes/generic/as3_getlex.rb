module AVM2::ABC
  class AS3GetLex < Opcode
    instruction 0x60

    body do
      vuint30 :property_index
    end

    consume 0
    produce 1
  end
end