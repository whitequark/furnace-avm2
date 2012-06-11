module Furnace::AVM2::ABC
  class AS3CoerceS < TypeConversionOpcode
    instruction 0x85

    consume 1
    produce 1

    ast_type :coerce
    type     :string
  end
end