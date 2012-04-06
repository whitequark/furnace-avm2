module Furnace::AVM2::Tokens
  class NamespaceNameToken < Furnace::Code::TerminalToken
    def initialize(origin, name, options={})
      super(origin, options)
      @name = name
    end

    def to_text
      if @name == "*"
        nil
      else
        @name
      end
    end
  end
end