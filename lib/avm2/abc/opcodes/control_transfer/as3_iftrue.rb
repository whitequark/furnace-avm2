module AVM2::ABC
  class AS3IfTrue < ControlTransferOpcode
    instruction 0x11
    int24       :jump_offset

    consume 1
    produce 0

    conditional true
  end
end