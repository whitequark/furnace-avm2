module Furnace::AVM2::ABC
  class AS3IfStrictNe < ControlTransferOpcode
    instruction 0x1a
    write_barrier :memory

    body do
      int24     :jump_offset
    end

    consume 2
    produce 0

    conditional true
  end
end