module Furnace::AVM2::Tokens
  class ScopeToken < Furnace::Code::SurroundedToken
    def text_before
      if @options[:function]
        " {\n"
      else
        "{\n"
      end
    end

    def text_after
      if @options[:continuation]
        "} "
      elsif @options[:closure]
        "}"
      else
        "}\n"
      end
    end

    def to_text
      "#{text_before}#{indent(children.map(&:to_text).join, @options)}#{text_after}"
    end
  end
end