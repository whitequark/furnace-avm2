module AVM2::ABC
  class AS3IfNGt < ControlTransferOpcode
    instruction 0x0e

    body do
      int24     :jump_offset
    end

    consume 2
    produce 0

    conditional true
  end
end