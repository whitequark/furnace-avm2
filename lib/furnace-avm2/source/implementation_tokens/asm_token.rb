module Furnace::AVM2::Tokens
  class AsmToken < Furnace::Code::TerminalToken
    include IsSimple

    def to_text
      'asm'
    end
  end
end