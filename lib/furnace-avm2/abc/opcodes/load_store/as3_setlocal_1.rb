module Furnace::AVM2::ABC
  class AS3SetLocal1 < LoadStoreOpcode
    instruction 0xd5
    write_barrier :local

    consume 1
    produce 0

    index     1
    direction :store
  end
end