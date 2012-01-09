module AVM2::ABC
  class AS3IfGe < ControlTransferOpcode
    instruction 0x18
    int24       :jump_offset

    consume 2
    produce 0

    conditional true
  end
end