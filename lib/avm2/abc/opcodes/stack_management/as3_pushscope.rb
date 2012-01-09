module AVM2::ABC
  class AS3PushScope < StackManagementOpcode
    instruction 0x30

    consume 1
    produce 0
  end
end