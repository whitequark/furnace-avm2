module AVM2::ABC
  class AS3SetProperty < Opcode
    instruction 0x61
    vuint30 :property_index

    consume nil # TODO
    produce 1
  end
end