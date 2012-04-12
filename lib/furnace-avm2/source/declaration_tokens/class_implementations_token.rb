module Furnace::AVM2::Tokens
  class ClassImplementationsToken < Furnace::Code::SeparatedToken
    def initialize(origin, options={})
      super(origin, origin.interfaces.map { |iface|
        MultinameToken.new(origin, iface, options)
      }, options)
    end

    def text_before
      if @options[:environment] == :interface
        "extends "
      else
        "implements "
      end
    end

    def text_between
      ", "
    end

    def text_after
      " "
    end
  end
end