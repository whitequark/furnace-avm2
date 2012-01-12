module AVM2::ABC
  class AS3GetProperty < Opcode
    instruction 0x66

    body do
      vuint30 :property_index
    end

    consume nil # TODO
    produce 1
  end
end