module Furnace::AVM2::ABC
  class AS3CoerceB < TypeConversionOpcode
    instruction 0x76

    consume 1
    produce 1

    type :boolean
  end
end