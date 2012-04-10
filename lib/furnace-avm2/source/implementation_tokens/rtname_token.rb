module Furnace::AVM2::Tokens
  class RTNameToken < Furnace::Code::SeparatedToken
    include IsSimple

    def text_between
      "::"
    end
  end
end