module AVM2::ABC
  class AS3SetLocal2 < LoadStoreOpcode
    instruction 0xd6

    consume 1
    produce 0

    index     2
    direction :store
  end
end