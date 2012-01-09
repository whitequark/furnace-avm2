module AVM2::ABC
  class AS3DecLocal < ArithmeticOpcode
    instruction 0x94
    vuint30 :reg_index

    consume 0
    produce 0

    type :number
  end
end