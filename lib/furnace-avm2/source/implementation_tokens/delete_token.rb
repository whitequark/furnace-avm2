module Furnace::AVM2::Tokens
  class DeleteToken < Furnace::Code::SurroundedToken
    include IsEmbedded
    include IsComplex

    def text_before
      "delete "
    end
  end
end