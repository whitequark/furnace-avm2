module Furnace::AVM2::ABC
  class AS3NegateI < ArithmeticOpcode
    instruction 0xc4

    consume 1
    produce 1

    type :integer
    ast_type :negate
  end
end