module Furnace::AVM2::ABC
  class AS3SetLocal < LoadStoreOpcode
    instruction 0x63

    body do
      vuint30 :local_index
    end

    consume 1
    produce 0

    index     { body.local_index }
    direction :store
  end
end