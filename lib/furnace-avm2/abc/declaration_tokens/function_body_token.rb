require_relative 'scope_token'

module Furnace::AVM2::Tokens
  class FunctionBodyToken < ScopeToken
    def initialize(origin, options={})
      super(origin, Furnace::AVM2::Decompiler.new(origin, options).decompile, options)
    end

    def text_before
      " {\n"
    end

    def text_after
      "}\n\n"
    end
  end
end