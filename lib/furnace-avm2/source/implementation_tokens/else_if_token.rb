require_relative 'control_flow_token'

module Furnace::AVM2::Tokens
  class ElseIfToken < ControlFlowToken
    def keyword
      'else if'
    end
  end
end