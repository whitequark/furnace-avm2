module AVM2::ABC
  class AS3DecLocalI < ArithmeticOpcode
    instruction 0xc3
    vuint30 :reg_index

    consume 0
    produce 0

    type :integer
  end
end