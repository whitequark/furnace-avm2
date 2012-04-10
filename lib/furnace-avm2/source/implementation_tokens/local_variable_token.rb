module Furnace::AVM2::Tokens
  class LocalVariableToken < Furnace::Code::SurroundedToken
    def text_before
      "var "
    end
  end
end