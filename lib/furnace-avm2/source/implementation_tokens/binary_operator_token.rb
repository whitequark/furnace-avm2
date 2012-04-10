module Furnace::AVM2::Tokens
  class BinaryOperatorToken < Furnace::Code::SeparatedToken
    include IsComplex

    def initialize(origin, children, operator, options={})
      super(origin, children, options)
      @operator = operator
    end

    def text_between
      " #{@operator} "
    end
  end
end