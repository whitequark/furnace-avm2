module AVM2::ABC
  class AS3ConvertI < TypeConversionOpcode
    instruction 0x73

    consume 1
    produce 1

    type :integer
  end
end