module Furnace::AVM2::ABC
  class AS3Call < Opcode
    instruction 0x41
    write_barrier :memory

    body do
      vuint30 :arg_count
    end

    consume { 2 + body.arg_count }
    produce 1

    def disassemble_parameters
      "(#{body.arg_count})"
    end
  end
end