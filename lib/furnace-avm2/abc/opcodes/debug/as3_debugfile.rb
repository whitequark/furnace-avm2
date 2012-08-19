module Furnace::AVM2::ABC
  class AS3DebugFile < Opcode
    instruction 0xf1

    body do
      const_ref :file, :string
    end

    def parameters
      [ body.file ]
    end

    consume 0
    produce 0
  end
end