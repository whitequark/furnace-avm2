module Furnace::AVM2::ABC
  class AS3CoerceS < Opcode
    instruction 0x85

    consume 1
    produce 1

    type :string
  end
end