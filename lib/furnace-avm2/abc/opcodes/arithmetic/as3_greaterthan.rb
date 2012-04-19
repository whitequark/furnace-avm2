module Furnace::AVM2::ABC
  class AS3GreaterThan < Opcode
    instruction 0xaf
    ast_type :>

    consume 2
    produce 1
  end
end