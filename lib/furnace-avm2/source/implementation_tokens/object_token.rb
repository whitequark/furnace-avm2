module Furnace::AVM2::Tokens
  class ObjectToken < Furnace::Code::SeparatedToken
    include IsSimple

    def text_before
      "{ "
    end

    def text_between
      ", "
    end

    def text_after
      " }"
    end
  end
end