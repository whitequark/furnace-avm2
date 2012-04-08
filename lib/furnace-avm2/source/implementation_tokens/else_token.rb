module Furnace::AVM2::Tokens
  class ElseToken < Furnace::Code::NonterminalToken
    include IsToplevel

    def initialize(origin, body, options={})
      super(origin, [body], options)
      @body = body
    end

    def to_text
      header = "else"
      if @body.is_a? ScopeToken
        "#{header} #{@body.to_text}"
      else
        "#{header}\n#{indent @body.to_text}"
      end
    end

    def to_structure(options={})
      structurize "else ...", options
    end
  end
end