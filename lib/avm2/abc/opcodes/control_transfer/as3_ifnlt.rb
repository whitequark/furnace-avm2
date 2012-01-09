module AVM2::ABC
  class AS3IfNLt < ControlTransferOpcode
    instruction 0x0c
    int24       :jump_offset

    consume 2
    produce 0

    conditional true
  end
end