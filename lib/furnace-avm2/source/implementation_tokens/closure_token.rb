module Furnace::AVM2::Tokens
  class ClosureToken < CalleeToken
    def initialize(origin, body, options={})
      super(origin, [], body.method, body,
         options.merge({ closure: true }))
    end

    def text_before
      "function"
    end
  end
end