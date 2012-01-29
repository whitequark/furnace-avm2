module AVM2::ABC
  class AS3Equals < ArithmeticOpcode
    instruction 0xab
    ast_type :==

    consume 2
    produce 1
  end
end