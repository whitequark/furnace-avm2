module Furnace::AVM2::Tokens
  class CommentToken < Furnace::Code::TerminalToken
    def initialize(origin, content, options={})
      super(origin, options)
      @content = content
    end

    def to_text
      if @options[:commented]
        " #{@content}\n"
      elsif @content.is_a? Furnace::Code::Token
        "/*\n#{@content.to_text.rstrip}\n */\n\n"
      else
        "/* #{@content} */\n"
      end
    end

    def to_structure(options={})
      structurize "/* ... */", options
    end
  end
end