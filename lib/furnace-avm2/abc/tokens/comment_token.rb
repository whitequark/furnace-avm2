module Furnace::AVM2::Tokens
  class CommentToken < Furnace::Code::TerminalToken
    def initialize(origin, text, options={})
      super(origin, options)
      @text = text
    end

    def to_text
      "/* #{@text} */\n"
    end

    def to_structure(options={})
      structurize @text, options
    end
  end
end