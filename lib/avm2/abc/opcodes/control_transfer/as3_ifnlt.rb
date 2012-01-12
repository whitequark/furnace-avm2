module AVM2::ABC
  class AS3IfNLt < ControlTransferOpcode
    instruction 0x0c

    body do
      int24     :jump_offset
    end

    consume 2
    produce 0

    conditional true
  end
end