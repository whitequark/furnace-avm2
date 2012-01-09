module AVM2::ABC
  class AS3DecrementI < ArithmeticOpcode
    instruction 0xc1

    consume 1
    produce 1

    type :integer
  end
end