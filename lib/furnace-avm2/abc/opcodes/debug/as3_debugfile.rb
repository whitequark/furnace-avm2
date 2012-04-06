module Furnace::AVM2::ABC
  class AS3DebugFile < Opcode
    instruction 0xf1

    body do
      vuint30 :index
    end

    consume 0
    produce 0
  end
end