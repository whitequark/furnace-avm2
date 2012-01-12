module AVM2::ABC
  class AS3IfNle < ControlTransferOpcode
    instruction 0x0d

    body do
      int24     :jump_offset
    end

    consume 2
    produce 0

    conditional true
  end
end