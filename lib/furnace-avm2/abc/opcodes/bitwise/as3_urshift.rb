module Furnace::AVM2::ABC
  class AS3Urshift < Opcode
    instruction 0xa7
    write_barrier :memory

    consume 2
    produce 1
  end
end