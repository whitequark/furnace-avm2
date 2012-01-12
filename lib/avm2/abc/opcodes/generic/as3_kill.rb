module AVM2::ABC
  class AS3Kill < Opcode
    instruction 0x8

    body do
      vuint30 :local_index
    end

    consume 0
    produce 0
  end
end