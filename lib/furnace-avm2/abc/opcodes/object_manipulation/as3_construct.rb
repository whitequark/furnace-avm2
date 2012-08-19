module Furnace::AVM2::ABC
  class AS3Construct < Opcode
    instruction 0x42
    write_barrier :memory

    body do
      vuint30 :arg_count
    end

    consume { 1 + body.arg_count }
    produce 1
  end
end