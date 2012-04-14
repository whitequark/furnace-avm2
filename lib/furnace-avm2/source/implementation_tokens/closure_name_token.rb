module Furnace::AVM2::Tokens
  class ClosureNameToken < Furnace::Code::TerminalToken
    def to_text
      "function"
    end
  end
end