module AVM2::ABC
  class AS3Jump < ControlTransferOpcode
    instruction 0x10
    int24       :jump_offset

    consume 0
    produce 0

    conditional false
  end
end