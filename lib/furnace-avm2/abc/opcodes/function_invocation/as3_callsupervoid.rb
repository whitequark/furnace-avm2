module Furnace::AVM2::ABC
  class AS3CallSuperVoid < FunctionInvocationOpcode
    instruction 0x4e
    write_barrier :memory

    ast_type :call_super

    produce 0
  end
end