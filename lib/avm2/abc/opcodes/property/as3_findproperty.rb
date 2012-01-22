module AVM2::ABC
  class AS3FindProperty < PropertyOpcode
    instruction 0x5e

    implicit_operand true
    consume 0
    produce 1
  end
end