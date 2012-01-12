module AVM2::ABC
  class AS3DeleteProperty < Opcode
    instruction 0x6a

    body do
      vuint30 :property_index
    end

    consume nil # TODO
    produce 1
  end
end