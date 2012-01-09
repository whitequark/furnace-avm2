module AVM2::ABC
  class AS3IfEQ < ControlTransferOpcode
    instruction 0x13
    int24       :jump_offset

    consume 2
    produce 0

    conditional true
  end
end