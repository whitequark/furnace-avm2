module AVM2::ABC
  class AS3ApplyType < TypeConversionOpcode
    instruction 0x53

    body do
      vuint30 :argc
    end

    consume { argc + 1 }
    produce 1
  end
end