module Furnace::AVM2::ABC
  class AS3CallProperty < FunctionInvocationOpcode
    instruction 0x46

    ast_type :call_property

    produce 1
  end
end