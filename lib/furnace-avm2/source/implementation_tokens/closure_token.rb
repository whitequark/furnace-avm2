module Furnace::AVM2::Tokens
  class ClosureToken < CalleeToken
  	include IsComplex

    def initialize(origin, body, options={})
      super(origin, [
        ClosureNameToken.new(origin, options)
      ], body.method, body, options.merge({
        closure: true,
        index:   body.method_idx
      }))
    end
  end
end