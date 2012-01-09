module AVM2::ABC
  class AS3PushNull < StackManagementOpcode
    instruction 0x20

    consume 0
    produce 1

    type :null
  end
end