module AVM2::ABC
  class AS3GetSuper < Opcode
    instruction 0x04
    vuint30 :property_index

    consume nil # TODO
    produce 1
  end
end