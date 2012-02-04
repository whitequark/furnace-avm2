module Furnace::AVM2::ABC
  class AS3ConvertD < TypeConversionOpcode
    instruction 0x75

    consume 1
    produce 1

    type :double
  end
end