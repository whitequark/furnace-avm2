module Furnace::AVM2::ABC
  class AS3ConstructSuper < Opcode
    instruction 0x49
    write_barrier :memory

    body do
      vuint30 :arg_count
    end

    consume { 1 + body.arg_count }
    produce 0

    def disassemble_parameters
      "#{body.arg_count}"
    end
  end
end