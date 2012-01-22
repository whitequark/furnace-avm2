module AVM2::ABC
  class AS3HasNext2 < Opcode
    instruction 0x32

    body do
      vuint30 :object_reg
      vuint30 :index_reg
    end

    consume 0
    produce 1

    def parameters
      [ body.object_reg, body.index_reg ]
    end
  end
end