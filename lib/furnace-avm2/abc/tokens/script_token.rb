module Furnace::AVM2::Tokens
  class ScriptToken < Furnace::Code::NonterminalToken
    include TokenWithTraits

    def initialize(origin, options={})
      super(origin, [
        *transform_traits(origin, options.merge(static: false)),
      ], options)
    end
  end
end