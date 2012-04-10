module Furnace::AVM2::Tokens
  class VariableNameToken < Furnace::Code::TerminalToken
    include IsSimple

    def initialize(origin, name, options={})
      super(origin, options)
      @name = name
    end

    def to_text
      @name
    end
  end
end