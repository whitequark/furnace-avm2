module AVM2::ABC
  class AS3GetLex < Opcode
    instruction 0x60
    vuint30 :property_index

    consume 0
    produce 1
  end
end