module Furnace::AVM2::ABC
  class AS3GetLocal2 < LoadStoreOpcode
    instruction 0xd2
    read_barrier :local

    consume 0
    produce 1

    index     2
    direction :load
  end
end