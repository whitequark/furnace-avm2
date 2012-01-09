module AVM2::ABC
  class AS3GetDescendants < Opcode
    instruction 0x59
    vuint30 :property_index

    consume nil # TODO
    produce 1
  end
end