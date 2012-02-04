module Furnace::AVM2::ABC
  class AS3GetDescendants < PropertyOpcode
    instruction 0x59

    implicit_operand false
    consume 0
    produce 1
  end
end