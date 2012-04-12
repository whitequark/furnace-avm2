module Furnace::AVM2::Tokens
  class ClassToken < Furnace::Code::NonterminalToken
    include TokenWithTraits

    def initialize(origin, options={})
      if origin.interface?
        options = options.merge(environment: :interface)
      else
        options = options.merge(environment: :class)
      end

      super(origin, [
        ClassSpecifiersToken.new(origin, options),
        ClassNameToken.new(origin, options),
        (ClassInheritanceToken.new(origin, options) if origin.super_name),
        (ClassImplementationsToken.new(origin, options) if origin.interfaces.any?),
        ScopeToken.new(origin, [
          *transform_traits(origin.klass, options.merge(static: true, instance: origin)),
          (Furnace::Code::NewlineToken.new(origin, options) if origin.klass.traits.any?),
          *transform_traits(origin, options.merge(static: false, instance: origin)),
        ], options)
      ], options)
    end
  end
end