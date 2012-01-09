module AVM2::ABC
  class AS3IfNle < ControlTransferOpcode
    instruction 0x0d
    int24       :jump_offset

    consume 2
    produce 0

    conditional true
  end
end