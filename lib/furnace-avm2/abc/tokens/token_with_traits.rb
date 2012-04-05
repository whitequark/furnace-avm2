module Furnace::AVM2::Tokens
  module TokenWithTraits
    def transform_traits(origin, options)
      tokens = []

      vars, methods = origin.traits.partition do |trait|
        [:Class, :Slot, :Const].include? trait.kind
      end

      tokens += vars.map { |trait| transform_trait trait, options }

      if tokens.any?
        tokens << Furnace::Code::NewlineToken.new(origin, options)
      end

      if options[:type] == :class && !options[:static]
        tokens << FunctionToken.new(origin, options.merge(type: :constructor))
      end

      tokens += methods.map { |trait| transform_trait trait, options }

      tokens
    end

    def transform_trait(trait, options)
      case trait.kind
      when :Method
        FunctionToken.new(trait, options)
      when :Getter
        FunctionToken.new(trait, options.merge(type: :getter))
      when :Setter
        FunctionToken.new(trait, options.merge(type: :setter))
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