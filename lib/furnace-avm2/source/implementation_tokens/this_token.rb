module Furnace::AVM2::Tokens
  class ThisToken < Furnace::Code::TerminalToken
    include IsSimple

    def to_text
      "this"
    end
  end
end