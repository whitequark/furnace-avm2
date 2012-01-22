module AVM2::ABC
  class AS3IncLocalI < ArithmeticOpcode
    instruction 0xc2

    body do
      vuint30 :reg_index
    end

    consume 0
    produce 0

    type :integer

    def parameters
      [ body.reg_index ]
    end
  end
end