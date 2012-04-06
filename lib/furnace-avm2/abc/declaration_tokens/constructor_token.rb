require_relative 'callee_token'

module Furnace::AVM2::Tokens
  class ConstructorToken < CalleeToken
    def initialize(origin, options={})
      super(origin, [
        ConstructorSpecifiersToken.new(origin, options),
        FunctionNameToken.new(origin, [
          MultinameToken.new(origin, options[:instance].name, options.merge(omit_ns: true))
        ], options),
      ], origin.initializer, origin.initializer_body, options)
    end
  end
end