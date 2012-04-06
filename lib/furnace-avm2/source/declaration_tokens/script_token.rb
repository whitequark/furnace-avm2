module Furnace::AVM2::Tokens
  class ScriptToken < Furnace::Code::NonterminalToken
    include TokenWithTraits

    def initialize(origin, options={})
      options = options.merge(environment: :script)

      super(origin, [
        *transform_traits(origin, options.merge(static: false)),
        FunctionBodyToken.new(origin.initializer_body, options)
      ], options)
    end
  end
end