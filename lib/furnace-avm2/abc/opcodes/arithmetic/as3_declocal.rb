module Furnace::AVM2::ABC
  class AS3DecLocal < Opcode
    instruction 0x94

    body do
      vuint30 :reg_index
    end

    consume 0
    produce 0

    type :number
  end
end