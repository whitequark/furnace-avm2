module AVM2::ABC
  class AS3IfNGt < ControlTransferOpcode
    instruction 0x0e
    int24       :jump_offset

    consume 2
    produce 0

    conditional true
  end
end