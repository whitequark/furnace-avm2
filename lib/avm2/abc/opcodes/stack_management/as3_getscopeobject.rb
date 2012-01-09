module AVM2::ABC
  class AS3GetScopeObject < StackManagementOpcode
    instruction 0x65
    uint8 :scope_index

    consume 0
    produce 1
  end
end