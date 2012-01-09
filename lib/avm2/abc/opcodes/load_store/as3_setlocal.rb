module AVM2::ABC
  class AS3SetLocal < LoadStoreOpcode
    instruction 0x63
    vuint30 :local_index

    consume 1
    produce 0

    index     { local_index }
    direction :store
  end
end