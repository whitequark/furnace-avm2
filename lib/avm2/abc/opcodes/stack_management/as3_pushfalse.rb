module AVM2::ABC
  class AS3PushFalse < StackManagementOpcode
    instruction 0x27

    consume 0
    produce 1

    type :boolean
  end
end