module Furnace::AVM2::ABC
  class AS3LessEquals < ArithmeticOpcode
    instruction 0xae
    write_barrier :memory

    ast_type :<=

    consume 2
    produce 1
  end
end