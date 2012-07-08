module Furnace::AVM2::ABC
  class AS3GetLocal1 < LoadStoreOpcode
    instruction 0xd1
    read_barrier :local

    consume 0
    produce 1

    index     1
    direction :load
  end
end