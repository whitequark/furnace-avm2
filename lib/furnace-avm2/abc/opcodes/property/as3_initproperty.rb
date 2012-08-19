module Furnace::AVM2::ABC
  class AS3InitProperty < PropertyOpcode
    instruction 0x68
    write_barrier :memory

    implicit_operand false
    consume 1
    produce 0
  end
end