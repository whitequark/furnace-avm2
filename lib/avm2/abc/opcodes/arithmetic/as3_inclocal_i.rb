module AVM2::ABC
  class AS3IncLocalI < ArithmeticOpcode
    instruction 0xc2
    vuint30 :reg_index

    consume 0
    produce 0

    type :integer
  end
end