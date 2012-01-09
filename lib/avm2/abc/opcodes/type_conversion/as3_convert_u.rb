module AVM2::ABC
  class AS3ConvertU < TypeConversionOpcode
    instruction 0x74

    consume 1
    produce 1

    type :integer
  end
end