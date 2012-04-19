module Furnace::AVM2::ABC
  class AS3StrictEquals < Opcode
    instruction 0xac
    ast_type :===

    consume 2
    produce 1
  end
end