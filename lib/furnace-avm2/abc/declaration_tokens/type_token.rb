module Furnace::AVM2::Tokens
  class TypeToken < Furnace::Code::SurroundedToken
    def initialize(origin, multiname, options={})
      super(origin, [
        MultinameToken.new(origin, multiname, options),
      ], options)
    end

    def text_before
      ":"
    end
  end
end