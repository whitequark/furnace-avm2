module Furnace::AVM2::Tokens
  class ClosureToken < CalleeToken
    def initialize(origin, body, options={})
      super(origin, [
        ClosureNameToken.new(origin, options)
      ], body.method, body, options.merge({ closure: true }))
    end
  end
end