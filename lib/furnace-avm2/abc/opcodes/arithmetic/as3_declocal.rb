module Furnace::AVM2::ABC
  class AS3DecLocal < ArithmeticOpcode
    instruction 0x94
    write_barrier :local, :memory

    body do
      vuint30 :reg_index
    end

    consume 0
    produce 0

    type :number
  end
end