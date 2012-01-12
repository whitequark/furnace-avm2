module AVM2::ABC
  class AS3Coerce < TypeConversionOpcode
    instruction 0x80

    body do
      vuint30 :type_index
    end

    consume 1
    produce 1
  end
end