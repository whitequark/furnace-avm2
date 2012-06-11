module Furnace::AVM2::ABC
  class AS3DecLocalI < ArithmeticOpcode
    instruction 0xc3

    body do
      vuint30 :reg_index
    end

    consume 0
    produce 0

    type :integer
    ast_type :dec_local
  end
end