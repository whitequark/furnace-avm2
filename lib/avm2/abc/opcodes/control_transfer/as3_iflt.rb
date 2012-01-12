module AVM2::ABC
  class AS3IfLt < ControlTransferOpcode
    instruction 0x15

    body do
      int24     :jump_offset
    end

    consume 2
    produce 0

    conditional true
  end
end