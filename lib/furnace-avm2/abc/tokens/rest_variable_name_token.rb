require_relative 'variable_name_token'

module Furnace::AVM2::Tokens
  class RestVariableNameToken < VariableNameToken
    def to_text
      "...#{@name}"
    end
  end
end