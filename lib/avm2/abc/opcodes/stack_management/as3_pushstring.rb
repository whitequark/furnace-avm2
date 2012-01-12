module AVM2::ABC
  class AS3PushString < StackManagementOpcode
    instruction 0x2c

    body do
      vuint30 :string_index
    end

    consume 0
    produce 1

    type :string
  end
end