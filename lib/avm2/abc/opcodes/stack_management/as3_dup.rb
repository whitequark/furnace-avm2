module AVM2::ABC
  class AS3Swap < StackManagementOpcode
    instruction 0x2a

    consume 1
    produce 2
  end
end