module Furnace::AVM2::Tokens
  class AsToken < Furnace::Code::SeparatedToken
    include IsEmbedded
    include IsComplex

    def text_between
      " as "
    end
  end
end