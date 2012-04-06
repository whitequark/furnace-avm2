module Furnace::AVM2::Tokens
  class ArrayToken < Furnace::Code::SeparatedToken
    include IsEmbedded
    include IsSimple

    def text_before
      "[ "
    end

    def text_between
      ", "
    end

    def text_after
      " ]"
    end
  end
end