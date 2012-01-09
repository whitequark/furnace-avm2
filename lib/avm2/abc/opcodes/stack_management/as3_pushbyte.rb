module AVM2::ABC
  class AS3PushByte < StackManagementOpcode
    instruction 0x24
    uint8 :byte_value

    consume 0
    produce 1

    type :integer
  end
end