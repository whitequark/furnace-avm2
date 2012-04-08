require_relative 'control_flow_token'

module Furnace::AVM2::Tokens
  class DoToken < ControlFlowToken
    def keyword
      'do'
    end
  end
end