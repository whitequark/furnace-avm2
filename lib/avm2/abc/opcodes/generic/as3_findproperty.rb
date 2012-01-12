module AVM2::ABC
  class AS3FindProperty < Opcode
    instruction 0x5e

    body do
      vuint30 :property_index
    end

    consume nil # TODO
    produce 1
  end
end