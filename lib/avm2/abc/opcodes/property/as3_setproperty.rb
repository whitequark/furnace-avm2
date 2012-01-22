module AVM2::ABC
  class AS3SetProperty < PropertyOpcode
    instruction 0x61

    implicit_operand false
    consume 1
    produce 0
  end
end