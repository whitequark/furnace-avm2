module Furnace::AVM2::ABC
  class AS3Not < Opcode
    instruction 0x96
    ast_type :!

    consume 1
    produce 1
  end
end