module AVM2::ABC
  class AS3SetSuper < Opcode
    instruction 0x05

    body do
      vuint30 :property_index
    end

    consume nil # TODO
    produce 0
  end
end