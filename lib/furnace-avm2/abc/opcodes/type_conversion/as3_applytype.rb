module Furnace::AVM2::ABC
  class AS3ApplyType < Opcode
    instruction 0x53

    body do
      vuint30 :argc
    end

    consume { body.argc + 1 }
    produce 1
  end
end