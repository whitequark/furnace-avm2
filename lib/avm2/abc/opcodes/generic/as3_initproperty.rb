module AVM2::ABC
  class AS3InitProperty < Opcode
    instruction 0x68
    vuint30 :property_index

    consume nil # TODO
    produce 0
  end
end