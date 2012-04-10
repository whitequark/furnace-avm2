module Furnace::AVM2::Tokens
  class SuperToken < Furnace::Code::TerminalToken
    include IsSimple

    def to_text
      "super"
    end
  end
end