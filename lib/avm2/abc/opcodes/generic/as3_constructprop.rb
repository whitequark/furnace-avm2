module AVM2::ABC
  class AS3ConstructProperty < Opcode
    instruction 0x4a
    vuint30 :property_index
    vuint30 :arg_count

    consume nil # TODO
    produce 1
  end
end