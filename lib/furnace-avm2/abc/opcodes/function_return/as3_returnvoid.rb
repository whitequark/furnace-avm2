module Furnace::AVM2::ABC
  class AS3ReturnVoid < FunctionReturnOpcode
    instruction 0x47

    ast_type :return

    consume 0
    produce 0
  end
end