module AVM2::ABC
  class AS3NewClass < Opcode
    instruction 0x58

    body do
      vuint30 :klass_index
    end

    consume 1
    produce 1
  end
end