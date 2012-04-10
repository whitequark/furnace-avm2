module Furnace::AVM2::Tokens
  class ControlFlowToken < Furnace::Code::NonterminalToken

    def initialize(origin, condition, body, options={})
      super(origin, [condition, body], options)
      @condition, @body = condition, body
    end

    def keyword
      raise "reimplement ControlFlowToken#keyword in a subclass"
    end

    def to_text
      header = "#{keyword}(#{@condition.to_text})"
      if @body.is_a? ScopeToken
        "#{header} #{@body.to_text}"
      else
        "#{header}\n#{indent @body.to_text}"
      end
    end

    def to_structure(options={})
      structurize "#{keyword}(...) ...", options
    end
  end
end