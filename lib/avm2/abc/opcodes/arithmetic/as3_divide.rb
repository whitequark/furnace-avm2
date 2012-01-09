module AVM2::ABC
  class AS3Divide < ArithmeticOpcode
    instruction 0xa3

    consume 2
    produce 1

    type :number
  end
end