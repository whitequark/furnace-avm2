require_relative 'control_flow_token'

module Furnace::AVM2::Tokens
  class IfToken < ControlFlowToken
    def keyword
      'if'
    end
  end
end