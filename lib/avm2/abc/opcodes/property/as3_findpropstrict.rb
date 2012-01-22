module AVM2::ABC
  class AS3FindPropertyStrict < PropertyOpcode
    instruction 0x5d

    implicit_operand true
    consume 0
    produce 1
  end
end