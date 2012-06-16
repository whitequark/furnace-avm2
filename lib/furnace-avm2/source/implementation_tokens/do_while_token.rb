module Furnace::AVM2::Tokens
  class DoWhileToken < Furnace::Code::NonterminalToken
    def initialize(origin, body, condition, options={})
      super(origin, [body, condition], options)
      @condition, @body = condition, body
    end

    def to_text
      "do #{@body.to_text}while(#{@condition.to_text});\n"
    end

    def to_structure(options={})
      structurize "do ... while(...)", options
    end
  end
end