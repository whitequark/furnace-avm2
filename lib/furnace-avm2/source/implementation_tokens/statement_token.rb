module Furnace::AVM2::Tokens
  class StatementToken < Furnace::Code::SurroundedToken

    def text_after
      ";\n"
    end
  end
end