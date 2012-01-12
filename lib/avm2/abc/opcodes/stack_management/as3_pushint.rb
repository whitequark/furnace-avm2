module AVM2::ABC
  class AS3PushInt < StackManagementOpcode
    instruction 0x2d

    body do
      vuint30 :int_value
    end

    consume 0
    produce 1

    type :integer
  end
end