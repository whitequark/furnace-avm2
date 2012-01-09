module AVM2::ABC
  class AS3GreaterThan < ArithmeticOpcode
    instruction 0xad

    consume 2
    produce 1
  end
end