module AVM2::ABC
  class AS3SetProperty < Opcode
    instruction 0x61

    body do
      vuint30 :property_index
    end

    consume nil # TODO
    produce 1
  end
end