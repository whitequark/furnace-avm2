module Furnace::AVM2::Tokens
  class StatementToken < Furnace::Code::SurroundedToken
    include IsToplevel

    def text_after
      ";\n"
    end
  end
end