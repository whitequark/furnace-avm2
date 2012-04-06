module Furnace::AVM2::Tokens
  class LocalVariableToken < Furnace::Code::SurroundedToken
    include IsToplevel

    def text_before
      "var "
    end

    def text_after
      ";\n"
    end
  end
end