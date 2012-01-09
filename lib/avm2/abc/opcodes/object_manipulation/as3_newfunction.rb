module AVM2::ABC
  class AS3NewFunction < Opcode
    instruction 0x40
    vuint30 :method_index

    consume 0
    produce 1
  end
end