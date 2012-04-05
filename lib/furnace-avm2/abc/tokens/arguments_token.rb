module Furnace::AVM2::Tokens
  class ArgumentsToken < Furnace::Code::SeparatedToken
    def text_before
      "("
    end

    def text_after
      ")"
    end

    def text_between
      ", "
    end
  end
end