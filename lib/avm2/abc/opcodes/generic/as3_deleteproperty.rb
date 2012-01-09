module AVM2::ABC
  class AS3DeleteProperty < Opcode
    instruction 0x6a
    vuint30 :property_index

    consume nil # TODO
    produce 1
  end
end