module AVM2::ABC
  class AS3IfGt < ControlTransferOpcode
    instruction 0x17
    int24       :jump_offset

    consume 2
    produce 0

    conditional true
  end
end