module Furnace::AVM2::ABC
  class AS3NewFunction < Opcode
    instruction 0x40

    body do
      vuint30 :method_idx
    end

    consume 0
    produce 1

    def parameters
      [ body.method_idx ]
    end
  end
end