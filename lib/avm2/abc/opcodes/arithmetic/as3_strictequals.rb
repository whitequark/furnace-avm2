module AVM2::ABC
  class AS3StrictEquals < ArithmeticOpcode
    instruction 0xac
    ast_type :===

    consume 2
    produce 1
  end
end