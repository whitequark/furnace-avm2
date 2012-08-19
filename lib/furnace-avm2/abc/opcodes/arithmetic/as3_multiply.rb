module Furnace::AVM2::ABC
  class AS3Multiply < ArithmeticOpcode
    instruction 0xa2
    write_barrier :memory

    consume 2
    produce 1

    type :number
  end
end