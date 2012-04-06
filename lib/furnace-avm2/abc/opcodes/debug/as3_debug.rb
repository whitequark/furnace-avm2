module Furnace::AVM2::ABC
  class AS3Debug < Opcode
    instruction 0xef

    body do
      uint8   :debug_type
      vuint30 :index
      uint8   :reg
      vuint30 :extra
    end

    consume 0
    produce 0
  end
end