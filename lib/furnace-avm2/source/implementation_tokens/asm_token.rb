module Furnace::AVM2::Tokens
  class AsmToken < Furnace::Code::TerminalToken

    def to_text
      'asm'
    end
  end
end