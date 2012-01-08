module AVM2::ABC
  class AS3Add < ArithmeticOpcode
    instruction 0xa0

    stack_pop  2
    stack_push 1
  end
end