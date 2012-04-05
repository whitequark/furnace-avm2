module Furnace::AVM2::Tokens
  class SlotToken < Furnace::Code::SurroundedToken
    def initialize(origin, options={})
      super(origin, [
        SpecifiersToken.new(origin, options),
        SlotNameToken.new(origin, options),
        (TypeToken.new(origin, origin.type, options) if origin.type)
      ], options)

      if origin.printable_value
        @children << AssignmentToken.new(origin, [
          VariableValueToken.new(origin, origin.printable_value, options)
        ], @options)
      end
    end

    def text_after
      ";\n"
    end
  end
end