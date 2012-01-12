module AVM2::ABC
  class AS3NewArray < Opcode
    instruction 0x56

    body do
      vuint30 :arg_count
    end

    consume { arg_count }
    produce 1
  end
end