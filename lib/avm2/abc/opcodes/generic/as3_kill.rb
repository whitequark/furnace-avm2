module AVM2::ABC
  class AS3Kill < Opcode
    instruction 0x8
    vuint30 :local_index

    consume 0
    produce 0
  end
end