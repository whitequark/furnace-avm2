module Furnace::AVM2::ABC
  class AS3IfTrue < ControlTransferOpcode
    instruction 0x11
    write_barrier :memory

    body do
      int24     :jump_offset
    end

    consume 1
    produce 0

    conditional true
  end
end