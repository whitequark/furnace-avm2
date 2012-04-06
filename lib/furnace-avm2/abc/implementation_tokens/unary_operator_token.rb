module Furnace::AVM2::Tokens
  class UnaryOperatorToken < Furnace::Code::SurroundedToken
    include IsEmbedded
    include IsSimple

    def initialize(origin, children, operator, options={})
      super(origin, children, options)
      @operator = operator
    end

    def text_before
      @operator.to_s
    end
  end
end