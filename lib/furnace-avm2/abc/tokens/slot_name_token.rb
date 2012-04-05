module Furnace::AVM2::Tokens
  class SlotNameToken < Furnace::Code::SurroundedToken
    def initialize(origin, options={})
      super(origin, [
        MultinameToken.new(origin, origin.name, options.merge(omit_ns: true))
      ], options)
    end

    def text_before
      if @options[:const]
        "const "
      else
        "var "
      end
    end
  end
end