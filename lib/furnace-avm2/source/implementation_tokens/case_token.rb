module Furnace::AVM2::Tokens
  class CaseToken < Furnace::Code::SurroundedToken
    def initialize(origin, value, options)
      super(origin, [ value ], options)
      @value = value
    end

    def text_before
      if @value
        "case "
      else
        "default"
      end
    end

    def text_after
      ":\n"
    end
  end
end