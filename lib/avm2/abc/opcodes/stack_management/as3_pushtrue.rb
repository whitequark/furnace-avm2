module AVM2::ABC
  class AS3PushTrue < StackManagementOpcode
    instruction 0x26

    consume 0
    produce 1

    type :boolean
  end
end