module Furnace::AVM2::Tokens
  class XmlLiteralToken < Furnace::Code::TerminalToken
    include IsSimple

    def initialize(origin, text, options={})
      super(origin, options)
      @text = text
    end

    def to_text
      @text
    end
  end
end