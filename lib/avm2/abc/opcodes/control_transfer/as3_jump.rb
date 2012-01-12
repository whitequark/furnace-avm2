module AVM2::ABC
  class AS3Jump < ControlTransferOpcode
    instruction 0x10

    body do
      int24     :jump_offset
    end

    consume 0
    produce 0

    conditional false

    def redundant?
      self.target == self.forward
    end
  end
end