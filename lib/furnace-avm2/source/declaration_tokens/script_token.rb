module Furnace::AVM2::Tokens
  class ScriptToken < Furnace::Code::NonterminalToken
    include TokenWithTraits

    def initialize(origin, options={})
      options = options.merge(environment: :script)

      super(origin, [
        *transform_traits(origin, options.merge(static: false)),
        Furnace::AVM2::Decompiler.new(origin.initializer_body, options).decompile
      ], options)
    end
  end
end