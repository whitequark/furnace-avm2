module Furnace::AVM2::Tokens
  class CatchFilterToken < Furnace::Code::SeparatedToken
    def text_between
      ": "
    end
  end
end