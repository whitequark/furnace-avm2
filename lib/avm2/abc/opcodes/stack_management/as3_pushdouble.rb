module AVM2::ABC
  class AS3PushDouble < StackManagementOpcode
    instruction 0x2f
    vuint30 :double_value

    consume 0
    produce 1

    type :double
  end
end