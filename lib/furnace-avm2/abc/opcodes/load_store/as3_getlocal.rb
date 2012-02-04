module Furnace::AVM2::ABC
  class AS3GetLocal < LoadStoreOpcode
    instruction 0x62

    body do
      vuint30 :local_index
    end

    consume 0
    produce 1

    index     { body.local_index }
    direction :load
  end
end