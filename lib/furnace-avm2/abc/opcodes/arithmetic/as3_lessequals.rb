module Furnace::AVM2::ABC
  class AS3LessEquals < Opcode
    instruction 0xae
    ast_type :<=

    consume 2
    produce 1
  end
end