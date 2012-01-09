module AVM2::ABC
  class AS3HasNext2 < Opcode
    instruction 0x32
    vuint30 :object_reg
    vuint30 :index_reg

    consume 0
    produce 1
  end
end