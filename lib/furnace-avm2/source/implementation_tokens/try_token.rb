module Furnace::AVM2::Tokens
  class TryToken < Furnace::Code::SeparatedToken
    def text_before
      "try "
    end

    def text_between
      " "
    end
  end
end