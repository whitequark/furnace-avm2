module Furnace::AVM2::ABC
  class AS3ConvertS < Opcode
    instruction 0x70

    consume 1
    produce 1

    type :string
  end
end