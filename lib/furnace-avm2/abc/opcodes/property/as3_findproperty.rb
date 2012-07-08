module Furnace::AVM2::ABC
  class AS3FindProperty < PropertyOpcode
    instruction 0x5e
    read_barrier :scope

    implicit_operand true
    consume 0
    produce 1
  end
end