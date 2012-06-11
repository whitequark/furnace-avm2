module Furnace::AVM2::ABC
  class AS3ConvertU < TypeConversionOpcode
    instruction 0x74

    consume 1
    produce 1

    ast_type :convert
    type     :unsigned
  end
end