module AVM2::ABC
  class AS3InstanceOf < Opcode
    instruction 0xb1

    consume 2
    produce 1
  end
end