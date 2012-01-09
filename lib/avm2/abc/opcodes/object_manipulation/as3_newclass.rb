module AVM2::ABC
  class AS3NewClass < Opcode
    instruction 0x58
    vuint30 :klass_index

    consume 1
    produce 1
  end
end