module AVM2::ABC
  class AS3ConstructSuper < Opcode
    instruction 0x49

    body do
      vuint30 :arg_count
    end

    consume { 1 + arg_count }
    produce 0
  end
end