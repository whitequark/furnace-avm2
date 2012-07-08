module Furnace::AVM2::ABC
  class AS3GetLocal0 < LoadStoreOpcode
    instruction 0xd0
    read_barrier :local

    consume 0
    produce 1

    index     0
    direction :load
  end
end