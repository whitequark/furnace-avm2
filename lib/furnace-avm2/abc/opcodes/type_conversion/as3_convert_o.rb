module Furnace::AVM2::ABC
  class AS3ConvertO < TypeConversionOpcode
    instruction 0x77

    consume 1
    produce 1

    ast_type :convert
    type     :object
  end
end