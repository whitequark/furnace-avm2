module Furnace::AVM2::Tokens
  class TypeToken < Furnace::Code::SurroundedToken
    def text_before
      ":"
    end
  end
end