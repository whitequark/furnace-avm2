module Furnace::AVM2::Tokens
  class ClassNameToken < Furnace::Code::SurroundedToken
    def initialize(origin, options={})
      super(origin, [
        MultinameToken.new(origin, origin.name, options)
      ], options)
    end

    def text_before
      if origin.interface?
        "interface "
      else
        "class "
      end
    end

    def text_after
      " "
    end
  end
end