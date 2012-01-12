module AVM2::ABC
  class AS3FindPropertyStrict < Opcode
    instruction 0x5d

    body do
      vuint30 :property_index
    end

    consume nil # TODO
    produce 1
  end
end