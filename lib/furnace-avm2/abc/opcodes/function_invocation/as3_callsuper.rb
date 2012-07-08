module Furnace::AVM2::ABC
  class AS3CallSuper < FunctionInvocationOpcode
    instruction 0x45

    ast_type :call_super

    produce 1
  end
end