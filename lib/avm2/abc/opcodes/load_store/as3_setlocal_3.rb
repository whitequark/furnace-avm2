module AVM2::ABC
  class AS3SetLocal3 < LoadStoreOpcode
    instruction 0xd7

    consume 1
    produce 0

    index     3
    direction :store
  end
end