module AVM2::ABC
  class AS3HasNext < Opcode
    instruction 0x1f

    consume 2
    produce 1
  end
end