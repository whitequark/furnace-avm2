module AVM2::ABC
  class AS3Decrement < ArithmeticOpcode
    instruction 0x93

    consume 1
    produce 1

    type :number
  end
end