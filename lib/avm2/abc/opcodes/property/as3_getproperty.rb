module AVM2::ABC
  class AS3GetProperty < PropertyOpcode
    instruction 0x66

    implicit_operand false
    consume 0
    produce 1
  end
end