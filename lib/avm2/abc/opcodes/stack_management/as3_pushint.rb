module AVM2::ABC
  class AS3PushInt < StackManagementOpcode
    instruction 0x2d
    vuint30 :int_value

    consume 0
    produce 1

    type :null
  end
end