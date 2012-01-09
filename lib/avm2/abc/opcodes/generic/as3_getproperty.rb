module AVM2::ABC
  class AS3GetProperty < Opcode
    instruction 0x66
    vuint30 :property_index

    consume nil # TODO
    produce 1
  end
end