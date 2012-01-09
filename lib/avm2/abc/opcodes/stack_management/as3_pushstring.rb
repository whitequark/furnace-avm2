module AVM2::ABC
  class AS3PushString < StackManagementOpcode
    instruction 0x2c
    vuint30 :string_index

    consume 0
    produce 1

    type :string
  end
end