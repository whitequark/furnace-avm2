module Furnace::AVM2::Tokens
  class InToken < Furnace::Code::SeparatedToken
    include IsEmbedded
    include IsComplex

    def text_between
      " in "
    end
  end
end