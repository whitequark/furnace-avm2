module AVM2::ABC
  class AS3IfStrictEq < ControlTransferOpcode
    instruction 0x19
    int24       :jump_offset

    consume 2
    produce 0

    conditional true
  end
end