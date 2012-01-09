module AVM2::ABC
  class AS3CallSuperVoid < Opcode
    instruction 0x4e
    vuint30 :property_index
    vuint30 :arg_count

    consume nil # TODO
    produce 0
  end
end