module Furnace::AVM2::ABC
  class AS3AddI < ArithmeticOpcode
    instruction 0xc5

    consume 2
    produce 1

    type :integer
    ast_type :add
  end
end