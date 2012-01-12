module AVM2::ABC
  class AS3GetSuper < Opcode
    instruction 0x04

    body do
      vuint30 :property_index
    end

    consume nil # TODO
    produce 1
  end
end