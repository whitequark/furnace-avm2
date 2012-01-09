module AVM2::ABC
  class AS3Subtract < ArithmeticOpcode
    instruction 0xa1

    consume 2
    produce 1

    type :number
  end
end