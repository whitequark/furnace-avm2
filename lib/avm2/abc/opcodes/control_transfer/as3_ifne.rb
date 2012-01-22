module AVM2::ABC
  class AS3IfNe < ControlTransferOpcode
    instruction 0x14

    body do
      int24     :jump_offset
    end

    consume 2
    produce 0

    conditional true
  end
end