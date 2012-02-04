module Furnace::AVM2::ABC
  class AS3NewObject < Opcode
    instruction 0x55

    body do
      vuint30 :arg_count
    end

    consume { body.arg_count * 2 }
    produce 1
  end
end