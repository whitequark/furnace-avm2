module AVM2::ABC
  class AS3Jump < ControlTransferOpcode
    instruction 0x10
    int24       :raw_offset

    conditional false
  end
end