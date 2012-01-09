module AVM2::ABC
  class AS3GetLocal < LoadStoreOpcode
    instruction 0x62
    vuint30 :local_index

    consume 0
    produce 1

    index     { local_index }
    direction :load
  end
end