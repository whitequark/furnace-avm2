module Furnace::AVM2::Tokens
  class IsToken < Furnace::Code::SeparatedToken
    include IsComplex

    def text_between
      " is "
    end
  end
end