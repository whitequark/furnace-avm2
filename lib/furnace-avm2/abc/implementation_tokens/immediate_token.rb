module Furnace::AVM2::Tokens
  class ImmediateToken < Furnace::Code::TerminalToken
    include IsEmbedded
    include IsSimple

    def initialize(origin, value, options={})
      super(origin, options)
      @value = value
    end

    def to_text
      @value
    end
  end
end