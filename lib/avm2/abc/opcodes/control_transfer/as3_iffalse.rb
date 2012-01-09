module AVM2::ABC
  class AS3IfFalse < ControlTransferOpcode
    instruction 0x12
    int24       :jump_offset

    consume 1
    produce 0

    conditional true
  end
end