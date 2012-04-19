module Furnace::AVM2::ABC
  class AS3GreaterEquals < Opcode
    instruction 0xb0
    ast_type :>=

    consume 2
    produce 1
  end
end