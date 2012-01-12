module AVM2::ABC
  class AS3GetScopeObject < StackManagementOpcode
    instruction 0x65

    body do
      uint8 :scope_index
    end

    consume 0
    produce 1
  end
end