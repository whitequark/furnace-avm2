module Furnace::AVM2::Tokens
  class LabelDeclarationToken < Furnace::Code::TerminalToken
    def initialize(origin, value, options={})
      super(origin, options)
      @value = value
    end

    def to_text
      "#{@value}: "
    end
  end
end