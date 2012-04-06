module Furnace::AVM2::Tokens
  class ClassInheritanceToken < Furnace::Code::SurroundedToken
    def initialize(origin, options={})
      super(origin, [
        MultinameToken.new(origin, origin.super_name, options)
      ], options)
    end

    def text_before
      "extends "
    end

    def text_after
      " "
    end
  end
end