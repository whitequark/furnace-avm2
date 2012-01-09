module AVM2::ABC
  class AS3NewArray < Opcode
    instruction 0x56
    vuint30 :arg_count

    consume { arg_count }
    produce 1
  end
end