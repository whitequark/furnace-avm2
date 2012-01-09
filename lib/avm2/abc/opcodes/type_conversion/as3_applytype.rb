module AVM2::ABC
  class AS3ApplyType < TypeConversionOpcode
    instruction 0x53
    vuint30 :argc

    consume { argc + 1 }
    produce 1
  end
end