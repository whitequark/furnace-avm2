module Furnace::AVM2::Tokens
  class GenericSpecializersToken < Furnace::Code::SeparatedToken
    include IsSimple

    def text_before
      "<"
    end

    def text_between
      ", "
    end

    def text_after
      ">"
    end
  end
end