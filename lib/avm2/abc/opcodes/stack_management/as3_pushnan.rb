module AVM2::ABC
  class AS3PushNan < StackManagementOpcode
    instruction 0x28

    consume 0
    produce 1

    type :nan
  end
end