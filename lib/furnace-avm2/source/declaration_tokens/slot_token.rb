module Furnace::AVM2::Tokens
  class SlotToken < Furnace::Code::SurroundedToken
    def initialize(origin, options={})
      super(origin, [
        MetadataToken.new(origin, options),
        SpecifiersToken.new(origin, options),
        SlotNameToken.new(origin, options),
        (TypeToken.new(origin, [
          MultinameToken.new(origin, origin.type, options)
        ], options) if origin.type)
      ], options)

      value = nil

      if options[:property_values]
        *, value = options[:property_values].find { |k,v| k == origin.name.to_astlet }
      end

      if value.nil?
        value = ImmediateToken.new(origin, origin.printable_value, options)
      end

      if value
        @children << InitializationToken.new(origin, [ value ], @options)
      end
    end

    def text_after
      ";\n"
    end
  end
end