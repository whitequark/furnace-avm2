module AVM2::ABC
  class AS3SetSuper < Opcode
    instruction 0x05
    vuint30 :property_index

    consume nil # TODO
    produce 0
  end
end