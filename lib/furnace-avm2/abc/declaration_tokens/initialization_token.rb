module Furnace::AVM2::Tokens
  class InitializationToken < Furnace::Code::SurroundedToken
    def text_before
      " = "
    end
  end
end