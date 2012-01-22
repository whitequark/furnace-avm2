module AVM2::ABC
  class AS3GetSuper < PropertyOpcode
    instruction 0x04

    implicit_operand false
    consume 0
    produce 1
  end
end