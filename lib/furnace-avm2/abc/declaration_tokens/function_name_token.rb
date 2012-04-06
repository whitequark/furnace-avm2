module Furnace::AVM2::Tokens
  class FunctionNameToken < Furnace::Code::SurroundedToken
    def text_before
      case @options[:type]
      when :getter
        "function get "
      when :setter
        "function set "
      else
        "function "
      end
    end
  end
end