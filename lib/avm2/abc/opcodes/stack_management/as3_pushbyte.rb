module AVM2::ABC
  class AS3PushByte < StackManagementOpcode
    instruction 0x24

    body do
      uint8 :byte_value
    end

    consume 0
    produce 1

    type :integer
  end
end