module AVM2::ABC
  class AS3FindPropertyStrict < Opcode
    instruction 0x5d
    vuint30 :property_index

    consume nil # TODO
    produce 1
  end
end