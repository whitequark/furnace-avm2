module Furnace::AVM2::ABC
  class TypeConversionOpcode < Opcode
    define_property :ast_type
    define_property :type

    def parameters
      [ type ]
    end
  end
end