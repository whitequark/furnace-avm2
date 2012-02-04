module Furnace::AVM2::ABC
  class AS3IfNge < ControlTransferOpcode
    instruction 0x0f

    body do
      int24     :jump_offset
    end

    consume 2
    produce 0

    conditional true
  end
end