module AVM2::ABC
  class AS3SetLocal1 < LoadStoreOpcode
    instruction 0xd5

    consume 1
    produce 0

    index     1
    direction :store
  end
end