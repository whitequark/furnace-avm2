module AVM2::ABC
  class AS3GetDescendants < Opcode
    instruction 0x59

    body do
      vuint30 :property_index
    end

    consume nil # TODO
    produce 1
  end
end