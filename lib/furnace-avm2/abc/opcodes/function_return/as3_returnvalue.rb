module Furnace::AVM2::ABC
  class AS3ReturnValue < FunctionReturnOpcode
    instruction 0x48

    ast_type :return

    consume 1
    produce 0
  end
end