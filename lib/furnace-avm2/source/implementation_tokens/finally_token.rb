module Furnace::AVM2::Tokens
  class FinallyToken < Furnace::Code::SeparatedToken
  	def initialize(origin, body, options={})
      super(origin, [ body ], options)
    end

    def text_before
      "finally "
    end
  end
end