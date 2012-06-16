module Furnace::AVM2::Tokens
  module TokenWithTraits
    def transform_traits(origin, options)
      tokens = []

      vars, methods = origin.traits.partition do |trait|
        [:Class, :Slot, :Const].include? trait.kind
      end

      if options[:environment] == :class && options[:static]
        if origin.initializer_body
          properties = Furnace::AVM2::Decompiler.new(
                origin.initializer_body, options).decompose_static_initializer
          options = options.merge(property_values: properties)
        end
      end

      tokens += vars.map { |trait| transform_trait trait, options }

      if tokens.any?
        tokens << Furnace::Code::NewlineToken.new(origin, options)
      end

      if options[:environment] == :class && !options[:static]
        tokens << ConstructorToken.new(origin, options)
      end

      tokens += methods.map { |trait| transform_trait trait, options }

      tokens
    end

    def transform_trait(trait, options)
      case trait.kind
      when :Method
        MethodToken.new(trait, options)
      when :Getter
        MethodToken.new(trait, options.merge(type: :getter))
      when :Setter
        MethodToken.new(trait, options.merge(type: :setter))
      when :Slot
        SlotToken.new(trait, options.merge(const: false))
      when :Const
        SlotToken.new(trait, options.merge(const: true))
      when :Class
        # nothing
      else
        CommentToken.new(trait, "%%#{trait.kind}", options)
      end
    end
  end
end