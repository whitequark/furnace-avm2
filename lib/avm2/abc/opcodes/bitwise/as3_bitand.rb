module AVM2::ABC
  class AS3BitAnd < BitwiseOpcode
    instruction 0xa8

    consume 2
    produce 1
  end
end