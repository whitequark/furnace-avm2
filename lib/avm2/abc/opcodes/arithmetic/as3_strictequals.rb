module AVM2::ABC
  class AS3StrictEquals < ArithmeticOpcode
    instruction 0xac

    consume 2
    produce 1
  end
end