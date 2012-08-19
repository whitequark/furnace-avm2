module Furnace::AVM2::ABC
  class AS3NewArray < Opcode
    instruction 0x56
    write_barrier :memory

    body do
      vuint30 :arg_count
    end

    consume { body.arg_count }
    produce 1
  end
end