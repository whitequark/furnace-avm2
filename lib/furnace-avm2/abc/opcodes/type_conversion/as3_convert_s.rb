module Furnace::AVM2::ABC
  class AS3ConvertS < TypeConversionOpcode
    instruction 0x70

    consume 1
    produce 1

    ast_type :convert
    type     :string
  end
end