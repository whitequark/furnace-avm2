module AVM2::ABC
  class AS3IfStrictNE < ControlTransferOpcode
    instruction 0x1a

    body do
      int24     :jump_offset
    end

    consume 1
    produce 0

    conditional true
  end
end