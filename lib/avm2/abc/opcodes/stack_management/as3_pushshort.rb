module AVM2::ABC
  class AS3PushShort < StackManagementOpcode
    instruction 0x25
    vuint30 :short_value

    consume 0
    produce 1

    type :null
  end
end