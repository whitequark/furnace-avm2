module Furnace::AVM2::Tokens
  class NewToken < Furnace::Code::SurroundedToken
    include IsEmbedded
    include IsSimple

    def text_before
      "new "
    end
  end
end