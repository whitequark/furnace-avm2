module AVM2::ABC
  class AS3FindProperty < Opcode
    instruction 0x5e
    vuint30 :property_index

    consume nil # TODO
    produce 1
  end
end