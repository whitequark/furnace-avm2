module AVM2::ABC
  class AS3Construct < Opcode
    instruction 0x42

    body do
      vuint30 :arg_count
    end

    consume { 1 + arg_count }
    produce 0
  end
end