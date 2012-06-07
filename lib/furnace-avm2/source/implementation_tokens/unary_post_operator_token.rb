module Furnace::AVM2::Tokens
  class UnaryPostOperatorToken < Furnace::Code::SurroundedToken
    include IsSimple

    def initialize(origin, child, operator, options={})
      super(origin, [ child ], options)
      @operator = operator
    end

    def text_after
      @operator.to_s
    end
  end
end