module Furnace::AVM2::ABC
  class AS3Equals < Opcode
    instruction 0xab
    ast_type :==

    consume 2
    produce 1
  end
end