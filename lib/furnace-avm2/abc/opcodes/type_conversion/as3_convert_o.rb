module Furnace::AVM2::ABC
  class AS3ConvertO < Opcode
    instruction 0x77

    consume 1
    produce 1

    type :object
  end
end