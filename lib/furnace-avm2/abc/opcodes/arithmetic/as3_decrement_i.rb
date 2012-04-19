module Furnace::AVM2::ABC
  class AS3DecrementI < Opcode
    instruction 0xc1

    consume 1
    produce 1

    type :integer
  end
end