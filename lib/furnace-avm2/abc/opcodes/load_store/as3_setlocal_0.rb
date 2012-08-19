module Furnace::AVM2::ABC
  class AS3SetLocal0 < LoadStoreOpcode
    instruction 0xd4
    write_barrier :local

    consume 1
    produce 0

    index     0
    direction :store
  end
end