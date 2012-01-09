module AVM2::ABC
  class AS3Call < Opcode
    instruction 0x41
    vuint30 :arg_count

    consume { 2 + arg_count }
    produce 1
  end
end