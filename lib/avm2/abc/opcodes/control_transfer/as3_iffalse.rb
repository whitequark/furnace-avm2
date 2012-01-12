module AVM2::ABC
  class AS3IfFalse < ControlTransferOpcode
    instruction 0x12

    body do
      int24     :jump_offset
    end

    consume 1
    produce 0

    conditional true
  end
end