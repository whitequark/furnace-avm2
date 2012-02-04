module Furnace::AVM2::ABC
  class AS3GetScopeObject < Opcode
    instruction 0x65

    body do
      uint8 :scope_index
    end

    consume 0
    produce 1

    def parameters
      [ body.scope_index ]
    end
  end
end