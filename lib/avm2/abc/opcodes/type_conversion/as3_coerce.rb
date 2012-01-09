module AVM2::ABC
  class AS3Coerce < TypeConversionOpcode
    instruction 0x80
    vuint32 :type_index

    consume 1
    produce 1
  end
end