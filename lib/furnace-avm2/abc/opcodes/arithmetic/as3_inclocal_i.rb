module Furnace::AVM2::ABC
  class AS3IncLocalI < ArithmeticOpcode
    instruction 0xc2
    write_barrier :local

    body do
      vuint30 :reg_index
    end

    consume 0
    produce 0

    type :integer
    ast_type :inc_local

    def parameters
      [ body.reg_index ]
    end
  end
end