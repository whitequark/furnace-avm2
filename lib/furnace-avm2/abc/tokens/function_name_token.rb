module Furnace::AVM2::Tokens
  class FunctionNameToken < Furnace::Code::SurroundedToken
    def initialize(origin, options={})
      super(origin, [
        MultinameToken.new(origin, origin.name, options.merge(omit_ns: true))
      ], options)
    end

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