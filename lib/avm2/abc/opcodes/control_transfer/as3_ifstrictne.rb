module AVM2::ABC
  class AS3IfStrictNE < ControlTransferOpcode
    instruction 0x1a
    int24       :jump_offset

    consume 1
    produce 0

    conditional true
  end
end