module Furnace::AVM2::ABC
  class AS3SetLocal3 < LoadStoreOpcode
    instruction 0xd7
    write_barrier :local

    consume 1
    produce 0

    index     3
    direction :store
  end
end