module AVM2::ABC
  class AS3InitProperty < Opcode
    instruction 0x68

    body do
      vuint30 :property_index
    end

    consume nil # TODO
    produce 0
  end
end