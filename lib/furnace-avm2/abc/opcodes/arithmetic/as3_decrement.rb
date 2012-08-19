module Furnace::AVM2::ABC
  class AS3Decrement < ArithmeticOpcode
    instruction 0x93
    write_barrier :memory

    consume 1
    produce 1

    type :number
  end
end