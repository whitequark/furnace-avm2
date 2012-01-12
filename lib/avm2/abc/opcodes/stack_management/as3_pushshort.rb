module AVM2::ABC
  class AS3PushShort < StackManagementOpcode
    instruction 0x25

    body do
      vuint30 :short_value
    end

    consume 0
    produce 1

    type :null
  end
end