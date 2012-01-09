module AVM2::ABC
  class AS3CoerceS < TypeConversionOpcode
    instruction 0x85

    consume 1
    produce 1

    type :string
  end
end