module AVM2::ABC
  class AS3PushUndefined < StackManagementOpcode
    instruction 0x21

    consume 0
    produce 1

    type :undefined
  end
end