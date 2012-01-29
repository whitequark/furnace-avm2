module AVM2::ABC
  class AS3LessThan < ArithmeticOpcode
    instruction 0xad
    ast_type :<

    consume 2
    produce 1
  end
end