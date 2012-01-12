module AVM2::ABC
  class AS3PushDouble < StackManagementOpcode
    instruction 0x2f

    body do
      vuint30 :double_value
    end

    consume 0
    produce 1

    type :double
  end
end