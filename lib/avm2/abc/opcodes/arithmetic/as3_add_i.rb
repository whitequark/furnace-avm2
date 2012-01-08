module AVM2::ABC
  class AS3AddI < ArithmeticOpcode
    instruction 0xa0
    vuint30     :operand

    stack_pop  2
    stack_push 1
  end
end