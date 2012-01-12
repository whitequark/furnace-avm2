module AVM2::ABC
  class AS3IncLocal < ArithmeticOpcode
    instruction 0x92

    body do
      vuint30 :reg_index
    end

    consume 0
    produce 0

    type :number
  end
end