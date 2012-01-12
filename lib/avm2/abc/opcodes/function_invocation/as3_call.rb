module AVM2::ABC
  class AS3Call < Opcode
    instruction 0x41

    body do
      vuint30 :arg_count
    end

    consume { 2 + arg_count }
    produce 1
  end
end