module Furnace::AVM2::Tokens
  class ScopeToken < Furnace::Code::SurroundedToken
    def text_before
      "{\n"
    end

    def text_after
      "}\n"
    end

    def to_text
      "#{text_before}#{indent(children.map(&:to_text).join, @options)}#{text_after}"
    end
  end
end