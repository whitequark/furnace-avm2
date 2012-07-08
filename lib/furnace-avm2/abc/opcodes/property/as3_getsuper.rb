module Furnace::AVM2::ABC
  class AS3GetSuper < PropertyOpcode
    instruction 0x04
    write_barrier :memory

    implicit_operand false
    consume 0
    produce 1
  end
end