module Furnace::AVM2::ABC
  class AS3GetLocal3 < LoadStoreOpcode
    instruction 0xd3
    read_barrier :local

    consume 0
    produce 1

    index     3
    direction :load
  end
end