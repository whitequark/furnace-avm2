module Furnace::AVM2::Tokens
  class ParenthesesToken < Furnace::Code::SurroundedToken
    def text_before
      "("
    end

    def text_after
      ")"
    end
  end
end