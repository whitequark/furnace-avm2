module Furnace::AVM2::Tokens
  class AccessToken < Furnace::Code::SeparatedToken
    include IsEmbedded
    include IsSimple

    def text_between
      "."
    end
  end
end