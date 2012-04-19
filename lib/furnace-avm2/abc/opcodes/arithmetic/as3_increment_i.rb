module Furnace::AVM2::ABC
  class AS3IncrementI < Opcode
    instruction 0xc0

    consume 1
    produce 1

    type :integer
  end
end