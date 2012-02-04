module Furnace::AVM2::ABC
  class AS3Jump < ControlTransferOpcode
    instruction 0x10

    body do
      int24     :jump_offset
    end

    consume 0
    produce 0

    conditional false

    def disassemble_parameters
      if body.jump_offset >= 0
        "+#{body.jump_offset}"
      else
        body.jump_offset.to_s
      end
    end
  end
end