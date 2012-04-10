module Furnace::AVM2::Tokens
  class TypeOfToken < Furnace::Code::SurroundedToken
    include IsSimple

    def text_before
      "typeof("
    end

    def text_after
      ")"
    end
  end
end