module AVM2::ABC
  class AS3NewCatch < ExceptionOpcode
    instruction 0x5a
    vuint30 :catch_index

    consume 0
    produce 1
  end
end