module AVM2::ABC
  class AS3Construct < Opcode
    instruction 0x42
    vuint30 :arg_count

    consume { 1 + arg_count }
    produce 0
  end
end