module Furnace::AVM2::Tokens
  class XAsmToken < Furnace::Code::SurroundedToken

    def text_before
      '__xasm<'
    end

    def text_after
      '>'
    end
  end
end
