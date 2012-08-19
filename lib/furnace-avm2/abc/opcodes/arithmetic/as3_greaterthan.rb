module Furnace::AVM2::ABC
  class AS3GreaterThan < ArithmeticOpcode
    instruction 0xaf
    write_barrier :memory

    ast_type :>

    consume 2
    produce 1
  end
end