module AVM2::ABC
  class AS3IfNGe < ControlTransferOpcode
    instruction 0x0f
    int24       :jump_offset

    consume 2
    produce 0

    conditional true
  end
end