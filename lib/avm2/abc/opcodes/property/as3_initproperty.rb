module AVM2::ABC
  class AS3InitProperty < PropertyOpcode
    instruction 0x68

    implicit_operand false
    consume 1
    produce 0
  end
end