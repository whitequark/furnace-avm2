module AVM2::ABC
  class AS3GreaterThan < ArithmeticOpcode
    instruction 0xaf

    consume 2
    produce 1
  end
end