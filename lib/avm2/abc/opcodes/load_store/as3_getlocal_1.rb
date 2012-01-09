module AVM2::ABC
  class AS3GetLocal1 < LoadStoreOpcode
    instruction 0xd1

    consume 0
    produce 1

    index     1
    direction :load
  end
end